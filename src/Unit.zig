const std = @import("std");

const Unit = @This();

name: []const u8,
symbol: []const u8 = "",
plural: ?[]const u8 = null,
aliases: []const []const u8 = &.{},
category: Category,
scale: f64 = 1.0,
offset: f64 = 0.0,
mode: Transform.Mode = .scale_then_offset,

pub const Index = enum(u32) {
    _,

    pub fn int(index: Index) u32 {
        return @intFromEnum(index);
    }

    pub fn from(value: usize) Index {
        return @enumFromInt(value);
    }
};

pub const Category = enum {
    money,
    data,
    energy,
    length,
    mass,
    power,
    pressure,
    temperature,
    time,
    velocity,
    volume,
};

pub const Transform = struct {
    scale: f64 = 1.0,
    offset: f64 = 0.0,
    mode: Mode = .scale_then_offset,

    pub const Mode = enum {
        scale_then_offset,
        offset_then_scale,
    };

    pub fn apply(transform: Transform, value: f64) f64 {
        return switch (transform.mode) {
            .scale_then_offset => value * transform.scale + transform.offset,
            .offset_then_scale => (value - transform.offset) / transform.scale,
        };
    }

    pub fn invert(transform: Transform) Transform {
        return .{
            .scale = transform.scale,
            .offset = transform.offset,
            .mode = switch (transform.mode) {
                .scale_then_offset => .offset_then_scale,
                .offset_then_scale => .scale_then_offset,
            },
        };
    }
};

pub const Spec = struct {
    name: []const u8,
    symbol: []const u8 = "",
    plural: ?[]const u8 = null,
    aliases: []const []const u8 = &.{},
    scale: f64 = 1.0,
    offset: f64 = 0.0,
    mode: Transform.Mode = .scale_then_offset,
};

pub fn table(comptime category: Category, comptime specs: []const Spec) [specs.len]Unit {
    comptime var units: [specs.len]Unit = undefined;
    inline for (specs, 0..) |spec, i| units[i] = .{
        .name = spec.name,
        .symbol = spec.symbol,
        .plural = spec.plural,
        .aliases = spec.aliases,
        .category = category,
        .scale = spec.scale,
        .offset = spec.offset,
        .mode = spec.mode,
    };
    return units;
}

pub fn toReference(unit: Unit) Transform {
    return .{ .scale = unit.scale, .offset = unit.offset, .mode = unit.mode };
}

pub fn pluralOf(unit: Unit, buffer: []u8) ?[]const u8 {
    if (unit.plural) |plural| return plural;
    if (unit.name.len + 1 > buffer.len) return null;
    @memcpy(buffer[0..unit.name.len], unit.name);
    buffer[unit.name.len] = 's';
    return buffer[0 .. unit.name.len + 1];
}

const testing = std.testing;

test table {
    const lengths = table(.length, &.{
        .{ .name = "meter", .symbol = "m" },
        .{ .name = "foot", .symbol = "ft", .plural = "feet", .scale = 0.3048 },
    });

    try testing.expectEqual(@as(usize, 2), lengths.len);
    try testing.expectEqual(Category.length, lengths[1].category);
    try testing.expectEqual(@as(f64, 1.0), lengths[0].scale);
    try testing.expectEqualStrings("feet", lengths[1].plural.?);
}

test pluralOf {
    var buffer: [64]u8 = undefined;

    const meter: Unit = .{ .name = "meter", .category = .length };
    try testing.expectEqualStrings("meters", meter.pluralOf(&buffer).?);

    const foot: Unit = .{ .name = "foot", .plural = "feet", .category = .length };
    try testing.expectEqualStrings("feet", foot.pluralOf(&buffer).?);
}

test "inverting a transform is exact" {
    const to_celsius: Transform = .{ .scale = 1.8, .offset = 32.0, .mode = .offset_then_scale };
    const to_fahrenheit = to_celsius.invert();

    try testing.expectEqual(@as(f64, 100.0), to_celsius.apply(212.0));
    try testing.expectEqual(@as(f64, 212.0), to_fahrenheit.apply(100.0));
    try testing.expectEqual(@as(f64, 0.0), to_celsius.apply(32.0));
    try testing.expectEqual(@as(f64, 32.0), to_fahrenheit.apply(0.0));
}

test "double inversion restores the original" {
    const transform: Transform = .{ .scale = 0.3048 };
    try testing.expectEqual(transform, transform.invert().invert());
}
