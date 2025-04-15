const std = @import("std");
const conversion = @import("../conversion.zig");

pub const Units = .{
    conversion.Unit{ .name = "watt", .plural = "+s", .symbol = "W", .ratio = 1.0, .category = conversion.Category.power },
    conversion.Unit{ .name = "quectowatt", .plural = "+s", .symbol = "qW", .ratio = 0.000000000000000000000000000001, .category = conversion.Category.power },
    conversion.Unit{ .name = "rontowatt", .plural = "+s", .symbol = "rW", .ratio = 0.000000000000000000000000001, .category = conversion.Category.power },
    conversion.Unit{ .name = "yoctowatt", .plural = "+s", .symbol = "yW", .ratio = 0.000000000000000000000001, .category = conversion.Category.power },
    conversion.Unit{ .name = "zeptowatt", .plural = "+s", .symbol = "zW", .ratio = 0.000000000000000000001, .category = conversion.Category.power },
    conversion.Unit{ .name = "attowatt", .plural = "+s", .symbol = "aW", .ratio = 0.000000000000000001, .category = conversion.Category.power },
    conversion.Unit{ .name = "femtowatt", .plural = "+s", .symbol = "fW", .ratio = 0.000000000000001, .category = conversion.Category.power },
    conversion.Unit{ .name = "picowatt", .plural = "+s", .symbol = "pW", .ratio = 0.000000000001, .category = conversion.Category.power },
    conversion.Unit{ .name = "nanowatt", .plural = "+s", .symbol = "nW", .ratio = 0.000000001, .category = conversion.Category.power },
    conversion.Unit{ .name = "microwatt", .plural = "+s", .symbol = "μW", .ratio = 0.000001, .category = conversion.Category.power },
    conversion.Unit{ .name = "milliwatt", .plural = "+s", .symbol = "mW", .ratio = 0.001, .category = conversion.Category.power },
    conversion.Unit{ .name = "centiwatt", .plural = "+s", .symbol = "cW", .ratio = 0.01, .category = conversion.Category.power },
    conversion.Unit{ .name = "deciwatt", .plural = "+s", .symbol = "dW", .ratio = 0.1, .category = conversion.Category.power },
    conversion.Unit{ .name = "decawatt", .plural = "+s", .symbol = "daW", .ratio = 10.0, .category = conversion.Category.power },
    conversion.Unit{ .name = "hectowatt", .plural = "+s", .symbol = "hW", .ratio = 100.0, .category = conversion.Category.power },
    conversion.Unit{ .name = "kilowatt", .plural = "+s", .symbol = "kW", .ratio = 1000.0, .category = conversion.Category.power },
    conversion.Unit{ .name = "megawatt", .plural = "+s", .symbol = "MW", .ratio = 1000000.0, .category = conversion.Category.power },
    conversion.Unit{ .name = "gigawatt", .plural = "+s", .symbol = "GW", .ratio = 1000000000.0, .category = conversion.Category.power },
    conversion.Unit{ .name = "terawatt", .plural = "+s", .symbol = "TW", .ratio = 1000000000000.0, .category = conversion.Category.power },
    conversion.Unit{ .name = "petawatt", .plural = "+s", .symbol = "PW", .ratio = 1000000000000000.0, .category = conversion.Category.power },
    conversion.Unit{ .name = "exawatt", .plural = "+s", .symbol = "EW", .ratio = 1000000000000000000.0, .category = conversion.Category.power },
    conversion.Unit{ .name = "zettawatt", .plural = "+s", .symbol = "ZW", .ratio = 1000000000000000000000.0, .category = conversion.Category.power },
    conversion.Unit{ .name = "yottawatt", .plural = "+s", .symbol = "YW", .ratio = 1000000000000000000000000.0, .category = conversion.Category.power },
    conversion.Unit{ .name = "ronnawatt", .plural = "+s", .symbol = "RW", .ratio = 1000000000000000000000000000.0, .category = conversion.Category.power },
    conversion.Unit{ .name = "quettawatt", .plural = "+s", .symbol = "QW", .ratio = 1000000000000000000000000000000.0, .category = conversion.Category.power },
};

const watt = Units[0];

pub fn load(graph: *conversion.ConversionGraph) !void {
    inline for (Units) |unit| {
        try graph.addConversion(unit, watt, unit.ratio);
    }
}
