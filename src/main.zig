const std = @import("std");

const commands = @import("commands.zig");
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
const token = @import("token.zig");

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

    var tokens = token.TokenList.init(gpallocator);
    defer tokens.deinit();
    try tokens.tokenize(&units);

    var t = task.Task.fromTokens(&tokens);
    const retval = try compute(&t, &graph, &units);
    std.process.exit(retval);
}

fn compute(t: *task.Task, graph: *conversion.ConversionGraph, units: *std.MultiArrayList(conversion.Unit)) !u8 {
    var stdout_buf: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout = &stdout_writer.interface;
    defer stdout.flush() catch {};
    const fV = t.*.fromValue orelse 0.0;
    const fU = t.*.fromUnit orelse "";
    const op = t.*.operation;
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

            const rfUnit = try conversion.getUnit(units, fU);
            const rtUnit = try conversion.getUnit(units, tU);

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
            var result: f64 = 0;

            switch (op) {
                .To => {
                    result = ((tV - fV) / fV) * 100;
                    if (result > 0) {
                        try stdout.print("+{d}%\n", .{result});
                    } else {
                        try stdout.print("{d}%\n", .{result});
                    }
                },
                .Of => {
                    if (std.mem.eql(u8, fU, "%")) {
                        result = (fV / 100.0) * tV;
                        try stdout.print("{d}\n", .{result});
                    } else {
                        result = (fV / tV) * 100.0;
                        try stdout.print("{d}%\n", .{result});
                    }
                },
                .Plus => {
                    result = fV + tV;
                    try stdout.print("{d}\n", .{result});
                },
                .Minus => {
                    result = fV - tV;
                    try stdout.print("{d}\n", .{result});
                },
                .Times => {
                    result = fV * tV;
                    try stdout.print("{d}\n", .{result});
                },
                .By => {
                    result = fV / tV;
                    try stdout.print("{d}\n", .{result});
                },
                .Power => {
                    result = std.math.pow(f64, fV, tV);
                    try stdout.print("{d}\n", .{result});
                },
                else => {
                    return error.NotImplemented;
                },
            }

            return 0;
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
