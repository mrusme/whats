const std = @import("std");

pub const Type = enum {
    Undefined,
    Conversion,
    Calculation,
};

pub const Task = struct {
    type: Type,
    fromValue: ?f64,
    fromUnit: ?[]u8,
    toValue: ?f64,
    toUnit: ?[]u8,
};
