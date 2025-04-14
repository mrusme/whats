const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Type = enum {
    Undefined,
    Conversion,
    Calculation,
};

pub const Task = struct {
    allocator: *Allocator,
    type: Type,
    fromValue: ?f64,
    fromUnit: ?[]u8,
    toValue: ?f64,
    toUnit: ?[]u8,

    fn deinit(self: *Task) void {
        if (self.allocator) |allocator| {
            allocator.free(self.term);
        }
    }
};
