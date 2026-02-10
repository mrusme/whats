const std = @import("std");
const conversion = @import("../conversion.zig");

pub const Units = [_]conversion.Unit{
    conversion.Unit{ .name = "meterpersecond", .plural = "+s", .symbol = "m/s", .ratio = 1.0, .category = conversion.Category.velocity },
    conversion.Unit{ .name = "kilometerperhour", .plural = "+s", .symbol = "km/h", .ratio = 1000.0 / 3600.0, .category = conversion.Category.velocity },
    conversion.Unit{ .name = "milesperhour", .plural = "+s", .symbol = "mph", .ratio = 1609.344 / 3600.0, .category = conversion.Category.velocity },
    conversion.Unit{ .name = "footpersecond", .plural = "+s", .symbol = "ft/s", .ratio = 0.3048, .category = conversion.Category.velocity },
    conversion.Unit{ .name = "knot", .plural = "+s", .symbol = "kn", .ratio = 1852.0 / 3600.0, .category = conversion.Category.velocity },
};

pub const reference_unit = Units[0];

pub fn load(graph: *conversion.ConversionGraph) !void {
    for (0.., Units) |i, unit| {
        try graph.addConversion(Units[i], reference_unit, unit.ratio);
    }
}
