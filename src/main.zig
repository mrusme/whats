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

    var t = task.Task.fromArgList(&argList);
    const retval = try compute(&t, &graph, &units);
    // https://github.com/ziglang/zig/issues/20369
    //     catch |err| switch (err) {
    //     error.InvalidTaskCommand => {
    //         try stdout.print("Invalid command\n", .{});
    //         std.process.exit(1);
    //     },
    //     error.InvalidUnit => {
    //         try stdout.print("Invalid unit\n", .{});
    //         std.process.exit(1);
    //     },
    //     error.InvalidTaskType => {
    //         try stdout.print("Internal error: invalid task type\n", .{});
    //         std.process.exit(2);
    //     },
    //     else => {
    //         try stdout.print("Internal error\n", .{});
    //         std.process.exit(2);
    //     },
    // };
    std.process.exit(retval);
}

fn compute(t: *task.Task, graph: *conversion.ConversionGraph, units: *std.MultiArrayList(conversion.Unit)) !u8 {
    const stdout = std.io.getStdOut().writer();
    const fV = t.*.fromValue orelse 0.0;
    const fU = t.*.fromUnit orelse "";
    const tV = t.*.toValue orelse 0.0;
    const tU = t.*.toUnit orelse "";

    switch (t.*.type) {
        task.Type.Command => {
            if (std.mem.eql(u8, fU, "-h") or std.mem.eql(u8, fU, "--help")) {
                try commands.help(units);
                return 0;
            } else if (std.mem.eql(u8, fU, "-v") or std.mem.eql(u8, fU, "--version")) {
                try commands.version();
                return 0;
            } else {
                return error.InvalidTaskCommand;
            }
        },
        task.Type.Conversion => {
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
            return 0;
        },
        task.Type.Calculation => {
            // TODO: Percentages etc
            return error.NotImplemented;
        },
        task.Type.Empty => {
            return error.NoTask;
        },
        else => {
            return error.InvalidTaskType;
        },
    }

    return 1;
}

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
