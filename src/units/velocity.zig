const Unit = @import("../Unit.zig");

pub const units = Unit.table(.velocity, &.{
    .{ .name = "meterpersecond", .symbol = "m/s" },
    .{ .name = "kilometerperhour", .symbol = "km/h", .scale = 1000.0 / 3600.0 },
    .{ .name = "milesperhour", .symbol = "mph", .scale = 1609.344 / 3600.0 },
    .{ .name = "footpersecond", .symbol = "ft/s", .scale = 0.3048 },
    .{ .name = "knot", .symbol = "kn", .scale = 1852.0 / 3600.0 },
});
