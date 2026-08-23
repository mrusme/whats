const Unit = @import("../Unit.zig");

pub const units = Unit.table(.money, &.{
    .{ .name = "EUR", .symbol = "EUR", .plural = "EURs" },
});
