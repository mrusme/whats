const std = @import("std");
const conversion = @import("../conversion.zig");

pub const Units = [_]conversion.Unit{
    conversion.Unit{ .name = "celsius", .plural = "celsius", .symbol = "C", .ratio = 1.0, .category = conversion.Category.temperature },
    conversion.Unit{ .name = "fahrenheit", .plural = "fahrenheit", .symbol = "F", .ratio = 1.0, .category = conversion.Category.temperature },
    conversion.Unit{ .name = "kelvin", .plural = "kelvin", .symbol = "K", .ratio = 1.0, .category = conversion.Category.temperature },
};

pub const reference_unit = Units[0];

pub fn load(graph: *conversion.ConversionGraph) !void {
    for (0.., Units) |i, unit| {
        try graph.addConversion(Units[i], reference_unit, unit.ratio);
    }
}
