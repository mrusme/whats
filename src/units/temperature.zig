const Unit = @import("../Unit.zig");

pub const units = Unit.table(.temperature, &.{
    .{ .name = "celsius", .symbol = "C", .plural = "celsius" },
    .{ .name = "fahrenheit", .symbol = "F", .plural = "fahrenheit", .scale = 1.8, .offset = 32.0, .mode = .offset_then_scale },
    .{ .name = "kelvin", .symbol = "K", .plural = "kelvin", .offset = 273.15, .mode = .offset_then_scale },
});
