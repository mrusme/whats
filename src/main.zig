const std = @import("std");

const commands = @import("commands.zig");
const arg = @import("arg.zig");
const conversion = @import("conversion.zig");
const data = @import("units/data.zig");
const energy = @import("units/energy.zig");
const lengths = @import("units/lengths.zig");
const mass = @import("units/mass.zig");
const money = @import("units/money.zig");
const power = @import("units/power.zig");
const pressure = @import("units/pressure.zig");
const temperature = @import("units/temperature.zig");
const time = @import("units/time.zig");
const volume = @import("units/volume.zig");
const task = @import("task.zig");

pub fn main() !void {
    // const allocator = std.heap.page_allocator;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            @panic("LEAK");
        }
    }
    const gpallocator = gpa.allocator();

    var graph = conversion.ConversionGraph.init(gpallocator);
    defer graph.deinit();

    const units_static =
        data.Units ++
        energy.Units ++
        lengths.Units ++
        mass.Units ++
        power.Units ++
        pressure.Units ++
        temperature.Units ++
        time.Units ++
        volume.Units;

    try data.load(&graph);
    try energy.load(&graph);
    try lengths.load(&graph);
    try mass.load(&graph);
    try power.load(&graph);
    try pressure.load(&graph);
    try temperature.load(&graph);
    try time.load(&graph);
    try volume.load(&graph);

    var units = try money.load(gpallocator, &graph);
    defer {
        for (units.items(.name), units.items(.symbol), units.items(.plural), units.items(.category)) |name, symbol, plural, category| {
            if (category == conversion.Category.money) {
                if (name.len > 0) gpallocator.free(name);
                if (symbol.len > 0) gpallocator.free(symbol);
                if (plural.len > 0) gpallocator.free(plural);
            }
        }
        units.deinit(gpallocator);
    }

    try units.ensureTotalCapacity(gpallocator, units.len + units_static.len);
    for (units_static) |unit| {
        try units.append(gpallocator, unit);
    }

    var argList = arg.ArgList.init(gpallocator);
    defer argList.deinit();
    try argList.parse();

    if (argList.termIs(0, "-h") or argList.termIs(0, "--help")) {
        try commands.help(&units);
        std.process.exit(0);
    } else if (argList.termIs(0, "-v") or argList.termIs(0, "--version")) {
        try commands.version();
        std.process.exit(0);
    }

    var t = taskFromArgs(&argList.argList);
    try compute(&t, &graph, &units);
}

fn taskFromArgs(argList: *const std.MultiArrayList(arg.Arg)) task.Task {
    if (argList.len < 2) {} else if (argList.len == 2) {
        // Example: 3m ft
        const arg1 = argList.get(0);
        const arg2 = argList.get(1);
        return task.Task{
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
                .type = task.Type.Conversion,
                .fromValue = arg1.value,
                .fromUnit = arg2.term,
                .toValue = arg4.value,
                .toUnit = arg4.term,
            };
        }
    }

    return task.Task{
        .type = task.Type.Undefined,
        .fromValue = null,
        .fromUnit = null,
        .toValue = null,
        .toUnit = null,
    };
}

fn compute(t: *task.Task, graph: *conversion.ConversionGraph, units: *std.MultiArrayList(conversion.Unit)) !void {
    const stdout = std.io.getStdOut().writer();
    const fV = t.*.fromValue orelse 0.0;
    const fU = t.*.fromUnit orelse "";
    const tV = t.*.toValue orelse 0.0;
    const tU = t.*.toUnit orelse "";

    std.log.debug("{d} {s} -> {d} {s}", .{ fV, fU, tV, tU });

    if (fU.len == 0 or tU.len == 0) {
        return error.InvalidUnit;
    }

    const rfUnit = try getUnit(units, fU);
    const rtUnit = try getUnit(units, tU);

    var tmp = fV;
    const path = try graph.resolveConversion(&rfUnit, &rtUnit);
    defer graph.allocator.free(path);
    for (path) |conv| {
        tmp = conv.apply(tmp);
        std.log.debug("{d}", .{tmp});
    }

    try stdout.print("{d}\n", .{tmp});
}

const UnitError = error{
    Oops,
};

fn getUnit(units: *std.MultiArrayList(conversion.Unit), input: []const u8) !conversion.Unit {
    if (input.len == 0) {
        return error.InvalidUnit;
    }

    const names = units.items(.name);
    const symbols = units.items(.symbol);
    const plurals = units.items(.plural);

    for (names, symbols, plurals, 0..) |name, symbol, plural, i| {
        if (symbol.len > 0 and std.mem.eql(u8, input, symbol)) {
            return units.get(i);
        } else if (name.len > 0 and std.ascii.eqlIgnoreCase(input, name)) {
            return units.get(i);
        } else if (plural.len > 0) {
            if (plural[0] == '+' and plural.len > 1 and
                slicesMatch(input, name, plural[1..]))
            {
                return units.get(i);
            } else if (std.mem.eql(u8, input, plural)) {
                return units.get(i);
            }
        }
    }

    return error.UnitNotFound;
}

fn slicesMatch(full: []const u8, a: []const u8, b: []const u8) bool {
    if (full.len != a.len + b.len) return false;

    return std.mem.eql(u8, full[0..a.len], a) and
        std.mem.eql(u8, full[a.len..], b);
}
