const std = @import("std");
const build_options = @import("build_options");

const arg = @import("arg.zig");
const conversion = @import("conversion.zig");
const data = @import("units/data.zig");
const energy = @import("units/energy.zig");
const lengths = @import("units/lengths.zig");
const mass = @import("units/mass.zig");
const money = @import("units/money.zig");
const power = @import("units/power.zig");
const pressure = @import("units/pressure.zig");
const time = @import("units/time.zig");
const volume = @import("units/volume.zig");
const task = @import("task.zig");

const VERSION = build_options.version;

const Units =
    data.Units ++
    energy.Units ++
    lengths.Units ++
    mass.Units ++
    power.Units ++
    pressure.Units ++
    time.Units ++
    volume.Units;

pub fn main() !void {
    var allocator = std.heap.page_allocator;
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

    try data.load(&graph);
    try energy.load(&graph);
    try lengths.load(&graph);
    try mass.load(&graph);
    try power.load(&graph);
    try pressure.load(&graph);
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

    try units.ensureTotalCapacity(gpallocator, units.len + Units.len);
    for (Units) |unit| {
        try units.append(gpallocator, unit);
    }

    var argsList = std.MultiArrayList(arg.Arg){};
    defer {
        while (argsList.pop()) |targ| {
            @constCast(&targ).deinit();
        }
        argsList.deinit(gpallocator);
    }

    var argsIter = try std.process.ArgIterator.initWithAllocator(allocator);
    defer argsIter.deinit();
    _ = argsIter.next();

    std.log.debug("Args:", .{});

    var i: usize = 0;
    while (argsIter.next()) |argStr| {
        var targ = arg.Arg{
            .allocator = &allocator,
        };

        _ = targ.parse(argStr);

        std.log.debug("{s} ", .{targ.term});
        if (std.mem.eql(u8, targ.term, "-h") or std.mem.eql(u8, targ.term, "--help")) {
            try showHelp(&units);
            std.process.exit(0);
        } else if (std.mem.eql(u8, targ.term, "-v") or std.mem.eql(u8, targ.term, "--version")) {
            try showVersion();
            std.process.exit(0);
        }

        if (targ.value) |number| {
            std.log.debug("{d} ", .{number});
        }

        i += 1;
        try argsList.ensureTotalCapacity(gpallocator, i);
        try argsList.append(gpallocator, targ);
    }

    var t = taskFromArgs(&argsList);
    try compute(&t, &graph, &units);
}

fn showHelp(units: *std.MultiArrayList(conversion.Unit)) !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("Usage: whats [OPTION]... NUMBER UNIT [in|of] NUMBER UNIT\n", .{});
    try stdout.print("A command for basic convertion and calculation.\n\n", .{});
    try stdout.print("  -h, --help       display this help and exit\n", .{});
    try stdout.print("  -v, --version    output version information and exit\n", .{});
    try stdout.print("\n", .{});

    try stdout.print("Units:\n", .{});
    try stdout.print("  {s: <8}{s: <24}\n", .{ "Symbol", "Name" });
    try stdout.print("--------------------------------------------------------------------------------\n", .{});
    var temp_category: conversion.Category = conversion.Category.none;
    var category_title: [32]u8 = [_]u8{0} ** 32;
    for (units.items(.name), units.items(.symbol), units.items(.category)) |name, symbol, category| {
        if (temp_category != category) {
            if (temp_category != conversion.Category.none) {
                try stdout.print("\n", .{});
            }
            temp_category = category;
            for (&category_title) |*item| {
                item.* = 0;
            }
            _ = std.ascii.upperString(&category_title, @tagName(category));
            try stdout.print("{s}:\n", .{category_title});
        }
        try stdout.print("  {s: <8}{s: <24}\n", .{ symbol, name });
    }
    try stdout.print("--------------------------------------------------------------------------------\n", .{});
    try stdout.print("Note:\n", .{});
    try stdout.print("  Symbols are case-sensitive, names are not.\n", .{});
    try stdout.print("\n", .{});

    try stdout.print("Examples:\n", .{});
    try stdout.print("  whats 2 meters in feet\n", .{});
    try stdout.print("  whats 1.21 gigawatts in watts\n", .{});
    try stdout.print("  whats 8 kg in grams\n", .{});
    try stdout.print("  whats 1024 KiB in MiB\n", .{});
    try stdout.print("\n", .{});
    try stdout.print("The [in|of] keywords are optional:\n", .{});
    try stdout.print("  whats 2 m ft\n", .{});
    try stdout.print("\n", .{});
    try stdout.print("Spaces are optional:\n", .{});
    try stdout.print("  whats 2m ft\n", .{});
    try stdout.print("\n", .{});

    try stdout.print("Report bugs at: https://github.com/mrusme/whats/issues\n", .{});
    try stdout.print("Home page: http://xn--gckvb8fzb.com/projects/whats/\n", .{});
}

fn showVersion() !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("whats version {s}\n", .{VERSION});
}

fn taskFromArgs(argList: *std.MultiArrayList(arg.Arg)) task.Task {
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
        std.log.debug("Conversion: {s} -> {s} using formula: {s}", .{ conv.from.name, conv.to.name, conv.formula });
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
