const std = @import("std");
const arg = @import("arg.zig");
const conversion = @import("conversion.zig");
const data = @import("units/data.zig");
const energy = @import("units/energy.zig");
const lengths = @import("units/lengths.zig");
const task = @import("task.zig");
const Allocator = std.mem.Allocator;

pub fn main() !void {
    var allocator = std.heap.page_allocator;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var gpa2 = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const gpallocator = gpa.allocator();
    const gpallocator2 = gpa2.allocator();

    var graph = conversion.ConversionGraph.init(gpallocator2);
    defer graph.deinit();

    try data.load(&graph);
    try energy.load(&graph);
    try lengths.load(&graph);

    var al = std.MultiArrayList(arg.Arg){};
    defer al.deinit(gpallocator);

    var argsIter = try std.process.ArgIterator.initWithAllocator(allocator);
    defer argsIter.deinit();
    _ = argsIter.next();

    std.debug.print("Args:", .{});

    var i: usize = 0;
    while (argsIter.next()) |argStr| {
        var targ = arg.Arg{
            .allocator = &allocator,
        };

        _ = targ.parse(argStr);
        // TODO: Where is this supposed to happen?
        // defer targ.deinit();

        std.debug.print("{s} ", .{targ.term});
        if (targ.value) |number| {
            std.debug.print("{d} ", .{number});
        }

        i += 1;
        try al.ensureTotalCapacity(gpallocator, i);
        try al.append(gpallocator, targ);
    }

    std.debug.print("\n", .{});

    // for (al.items(.term), al.items(.value)) |*term, *value| {
    //     std.debug.print("{s} {?d}\n", .{ term.*, value.* });
    // }

    // Examples:
    // 11m ft
    // 11m in ft
    // 11 m in ft
    //
    // 11cm in
    // 11cm in in
    // 11 cm in in

    var t = taskFromArgs(&allocator, &al);
    try compute(&t, &graph);
}

fn taskFromArgs(allocator: *Allocator, argList: *std.MultiArrayList(arg.Arg)) task.Task {
    if (argList.len < 2) {} else if (argList.len == 2) {
        // Example: 3m ft
        const arg1 = argList.get(0);
        const arg2 = argList.get(1);
        return task.Task{
            .allocator = allocator,
            .type = task.Type.Conversion,
            .fromValue = arg1.value,
            .fromUnit = arg1.term,
            .toValue = arg2.value,
            .toUnit = arg2.term,
        };
    } else if (argList.len == 3) {
        const arg1 = argList.get(0);
        const arg2 = argList.get(1);
        const arg3 = argList.get(2);

        if (std.mem.eql(u8, arg2.term, "in") or
            std.mem.eql(u8, arg2.term, "of"))
        {
            // Example: 22m in ft
            return task.Task{
                .allocator = allocator,
                .type = task.Type.Conversion,
                .fromValue = arg1.value,
                .fromUnit = arg1.term,
                .toValue = arg3.value,
                .toUnit = arg3.term,
            };
        } else {
            if (arg1.value != null and std.mem.eql(u8, arg1.term, "") and
                arg2.value == null and !std.mem.eql(u8, arg2.term, ""))
            {
                // Example: 22 m ft
                return task.Task{
                    .allocator = allocator,
                    .type = task.Type.Conversion,
                    .fromValue = arg1.value,
                    .fromUnit = arg2.term,
                    .toValue = arg3.value,
                    .toUnit = arg3.term,
                };
            }
        }
    } else if (argList.len == 4) {
        const arg1 = argList.get(0);
        const arg2 = argList.get(1);
        const arg3 = argList.get(2);
        const arg4 = argList.get(3);

        if (std.mem.eql(u8, arg3.term, "in") or
            std.mem.eql(u8, arg3.term, "of"))
        {
            // Example: 22 m in ft
            return task.Task{
                .allocator = allocator,
                .type = task.Type.Conversion,
                .fromValue = arg1.value,
                .fromUnit = arg2.term,
                .toValue = arg4.value,
                .toUnit = arg4.term,
            };
        }
    }

    return task.Task{
        .allocator = allocator,
        .type = task.Type.Undefined,
        .fromValue = null,
        .fromUnit = null,
        .toValue = null,
        .toUnit = null,
    };
}

fn compute(t: *task.Task, graph: *conversion.ConversionGraph) !void {
    const stdout = std.io.getStdOut().writer();
    const fV = t.*.fromValue orelse 0.0;
    const fU = t.*.fromUnit orelse "";
    const tV = t.*.toValue orelse 0.0;
    const tU = t.*.toUnit orelse "";

    std.debug.print("{d} {s} -> {d} {s}\n", .{ fV, fU, tV, tU });

    const rfUnit = getUnit(fU);
    const rtUnit = getUnit(tU);

    if (rfUnit == null or rtUnit == null) {
        return;
    }

    var tmp = fV;
    const path = try graph.resolveConversion(rfUnit.?, rtUnit.?);
    for (path) |conv| {
        stdout.print("Conversion: {s} -> {s} using formula: {s}\n", .{ conv.from.name, conv.to.name, conv.formula }) catch |err| {
            std.debug.print("error: {}\n", .{err});
            return;
        };
        tmp = conv.apply(tmp);
        try stdout.print("{d}\n", .{tmp});
    }
}

fn getUnit(input: []const u8) ?conversion.Unit {
    const units = data.Units ++ energy.Units ++ lengths.Units;
    inline for (units) |unit| {
        if (std.mem.eql(u8, input, unit.symbol)) {
            return unit;
        } else if (std.ascii.eqlIgnoreCase(input, unit.name)) {
            return unit;
        } else {
            if (unit.plural[0] == '+' and slicesMatch(input, unit.name, unit.plural[1..])) {
                return unit;
            } else if (std.mem.eql(u8, input, unit.plural)) {
                return unit;
            }
        }
    }

    return null;
}

fn slicesMatch(full: []const u8, a: []const u8, b: []const u8) bool {
    if (full.len != a.len + b.len) return false;

    return std.mem.eql(u8, full[0..a.len], a) and
        std.mem.eql(u8, full[a.len..], b);
}
