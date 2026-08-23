const std = @import("std");
const bfstree = @import("bfstree");

const Unit = @import("Unit.zig");

const Registry = @This();

const Allocator = std.mem.Allocator;

pub const max_term_len = 64;

const micro_sign = "\u{00b5}";
const greek_mu = "\u{03bc}";

pub const builtin = struct {
    pub const money = @import("units/money.zig");
    pub const data = @import("units/data.zig");
    pub const energy = @import("units/energy.zig");
    pub const length = @import("units/length.zig");
    pub const mass = @import("units/mass.zig");
    pub const power = @import("units/power.zig");
    pub const pressure = @import("units/pressure.zig");
    pub const temperature = @import("units/temperature.zig");
    pub const time = @import("units/time.zig");
    pub const velocity = @import("units/velocity.zig");
    pub const volume = @import("units/volume.zig");
};

pub const Options = struct {
    load_builtin: bool = true,
};

pub const ConvertError = error{
    IncompatibleUnits,
    UnknownUnit,
} || Allocator.Error;

pub const Transform = Unit.Transform;

const Edge = struct { from: Unit.Index, to: Unit.Index };

gpa: Allocator,
entries: std.ArrayList(Unit),
keys: std.ArrayList([]const u8),
owned: std.ArrayList([]const u8),
by_symbol: std.StringHashMapUnmanaged(Unit.Index),
by_name: std.StringHashMapUnmanaged(Unit.Index),
by_plural: std.StringHashMapUnmanaged(Unit.Index),
references: std.EnumMap(Unit.Category, Unit.Index),
transforms: std.AutoHashMapUnmanaged(Edge, Transform),
tree: bfstree.BFSTree,

pub fn init(gpa: Allocator, options: Options) Allocator.Error!Registry {
    var registry: Registry = .{
        .gpa = gpa,
        .entries = .empty,
        .keys = .empty,
        .owned = .empty,
        .by_symbol = .empty,
        .by_name = .empty,
        .by_plural = .empty,
        .references = .{},
        .transforms = .empty,
        .tree = bfstree.BFSTree.init(gpa),
    };
    errdefer registry.deinit();

    if (options.load_builtin) {
        inline for (@typeInfo(Unit.Category).@"enum".fields) |field| {
            try registry.addCategory(&@field(builtin, field.name).units);
        }
    }

    return registry;
}

pub fn deinit(registry: *Registry) void {
    const gpa = registry.gpa;
    registry.tree.deinit();
    registry.transforms.deinit(gpa);
    registry.by_plural.deinit(gpa);
    registry.by_name.deinit(gpa);
    registry.by_symbol.deinit(gpa);
    for (registry.owned.items) |text| gpa.free(text);
    registry.owned.deinit(gpa);
    registry.keys.deinit(gpa);
    registry.entries.deinit(gpa);
    registry.* = undefined;
}

pub fn addCategory(registry: *Registry, units: []const Unit) Allocator.Error!void {
    if (units.len == 0) return;

    const base = try registry.add(units[0]);
    registry.references.put(units[0].category, base);

    for (units[1..]) |unit| {
        const index = try registry.add(unit);
        try registry.link(index, base, unit.toReference());
    }
}

pub fn add(registry: *Registry, unit: Unit) Allocator.Error!Unit.Index {
    const gpa = registry.gpa;
    const index = Unit.Index.from(registry.entries.items.len);

    const key = try registry.lowerKey(unit.name);
    try registry.entries.append(gpa, unit);
    try registry.keys.append(gpa, key);

    if (unit.symbol.len > 0) {
        const slot = try registry.by_symbol.getOrPut(gpa, unit.symbol);
        if (!slot.found_existing) slot.value_ptr.* = index;
    }
    for (unit.aliases) |alias| {
        const slot = try registry.by_symbol.getOrPut(gpa, alias);
        if (!slot.found_existing) slot.value_ptr.* = index;
    }
    {
        const slot = try registry.by_name.getOrPut(gpa, key);
        if (!slot.found_existing) slot.value_ptr.* = index;
    }
    if (unit.plural) |plural| {
        const slot = try registry.by_plural.getOrPut(gpa, try registry.lowerKey(plural));
        if (!slot.found_existing) slot.value_ptr.* = index;
    }

    return index;
}

pub fn addOwned(registry: *Registry, unit: Unit) Allocator.Error!Unit.Index {
    var copy = unit;
    copy.name = try registry.intern(unit.name);
    if (unit.symbol.len > 0) copy.symbol = try registry.intern(unit.symbol);
    if (unit.plural) |plural| copy.plural = try registry.intern(plural);
    return registry.add(copy);
}

fn lowerKey(registry: *Registry, text: []const u8) Allocator.Error![]const u8 {
    for (text) |c| {
        if (std.ascii.isUpper(c)) break;
    } else return text;

    return std.ascii.lowerString(try registry.intern(text), text);
}

fn intern(registry: *Registry, text: []const u8) Allocator.Error![]u8 {
    const gpa = registry.gpa;
    const copy = try gpa.dupe(u8, text);
    errdefer gpa.free(copy);
    try registry.owned.append(gpa, copy);
    return copy;
}

pub fn link(registry: *Registry, from: Unit.Index, to: Unit.Index, transform: Transform) Allocator.Error!void {
    const gpa = registry.gpa;

    try registry.transforms.put(gpa, .{ .from = from, .to = to }, transform);
    try registry.transforms.put(gpa, .{ .from = to, .to = from }, transform.invert());

    const source = registry.keys.items[from.int()];
    const target = registry.keys.items[to.int()];

    try registry.tree.addEdge(.{ .from = source, .to = target });
    try registry.tree.addEdge(.{ .from = target, .to = source });
}

pub fn reference(registry: *const Registry, category: Unit.Category) ?Unit.Index {
    return registry.references.get(category);
}

pub fn at(registry: *const Registry, index: Unit.Index) Unit {
    return registry.entries.items[index.int()];
}

pub fn list(registry: *const Registry) []const Unit {
    return registry.entries.items;
}

pub fn find(registry: *const Registry, term: []const u8) ?Unit.Index {
    if (term.len == 0 or term.len > max_term_len) return null;

    var normalized: [max_term_len]u8 = undefined;
    const symbol = normalizeMicro(term, &normalized);
    if (registry.by_symbol.get(symbol)) |index| return index;

    var lowered: [max_term_len]u8 = undefined;
    const name = std.ascii.lowerString(lowered[0..symbol.len], symbol);
    if (registry.by_name.get(name)) |index| return index;
    if (registry.by_plural.get(name)) |index| return index;

    if (name.len > 1 and name[name.len - 1] == 's') {
        if (registry.by_name.get(name[0 .. name.len - 1])) |index| {
            if (registry.at(index).plural == null) return index;
        }
    }

    return null;
}

pub fn contains(registry: *const Registry, term: []const u8) bool {
    return registry.find(term) != null;
}

pub fn convert(registry: *Registry, value: f64, from: Unit.Index, to: Unit.Index) ConvertError!f64 {
    if (from == to) return value;

    const source = registry.at(from);
    const target = registry.at(to);
    if (source.category != target.category) return error.IncompatibleUnits;

    var path = try registry.tree.findPath(registry.keys.items[from.int()], registry.keys.items[to.int()]);
    const found = if (path) |*hit| hit else return error.IncompatibleUnits;
    defer found.deinit();

    var result = value;
    for (found.edges.items) |edge| {
        const step_from = registry.by_name.get(edge.from) orelse return error.UnknownUnit;
        const step_to = registry.by_name.get(edge.to) orelse return error.UnknownUnit;
        const transform = registry.transforms.get(.{ .from = step_from, .to = step_to }) orelse
            return error.IncompatibleUnits;
        result = transform.apply(result);
    }
    return result;
}

fn normalizeMicro(term: []const u8, buffer: []u8) []const u8 {
    if (std.mem.indexOf(u8, term, greek_mu) == null) return term;

    var len: usize = 0;
    var i: usize = 0;
    while (i < term.len) {
        if (std.mem.startsWith(u8, term[i..], greek_mu)) {
            if (len + micro_sign.len > buffer.len) return term;
            @memcpy(buffer[len..][0..micro_sign.len], micro_sign);
            len += micro_sign.len;
            i += greek_mu.len;
        } else {
            if (len + 1 > buffer.len) return term;
            buffer[len] = term[i];
            len += 1;
            i += 1;
        }
    }
    return buffer[0..len];
}

test "builtin names and symbols are unique" {
    var registry: Registry = try .init(std.testing.allocator, .{});
    defer registry.deinit();

    var names: std.StringHashMapUnmanaged(void) = .empty;
    defer names.deinit(std.testing.allocator);
    var symbols: std.StringHashMapUnmanaged(void) = .empty;
    defer symbols.deinit(std.testing.allocator);

    for (registry.list()) |unit| {
        const name_slot = try names.getOrPut(std.testing.allocator, unit.name);
        if (name_slot.found_existing) {
            std.debug.print("duplicate unit name: {s}\n", .{unit.name});
            return error.TestUnexpectedResult;
        }
        if (unit.symbol.len > 0) {
            const symbol_slot = try symbols.getOrPut(std.testing.allocator, unit.symbol);
            if (symbol_slot.found_existing) {
                std.debug.print("duplicate unit symbol: {s}\n", .{unit.symbol});
                return error.TestUnexpectedResult;
            }
        }
        for (unit.aliases) |alias| {
            const alias_slot = try symbols.getOrPut(std.testing.allocator, alias);
            if (alias_slot.found_existing) {
                std.debug.print("duplicate unit alias: {s}\n", .{alias});
                return error.TestUnexpectedResult;
            }
        }
    }
}

test "symbol lookup is case-sensitive" {
    var registry: Registry = try .init(std.testing.allocator, .{});
    defer registry.deinit();

    try std.testing.expectEqualStrings("meter", registry.at(registry.find("m").?).name);
    try std.testing.expectEqualStrings("megameter", registry.at(registry.find("Mm").?).name);
    try std.testing.expectEqual(@as(?Unit.Index, null), registry.find("KM"));
}

test "name lookup is case-insensitive" {
    var registry: Registry = try .init(std.testing.allocator, .{});
    defer registry.deinit();

    for ([_][]const u8{ "meter", "METER", "Meter", "meters", "METERS" }) |term| {
        const index = registry.find(term) orelse return error.TestUnexpectedResult;
        try std.testing.expectEqualStrings("meter", registry.at(index).name);
    }
}

test "explicit plurals" {
    var registry: Registry = try .init(std.testing.allocator, .{});
    defer registry.deinit();

    try std.testing.expectEqualStrings("foot", registry.at(registry.find("feet").?).name);
    try std.testing.expectEqualStrings("inch", registry.at(registry.find("inches").?).name);
    try std.testing.expectEqualStrings("millennium", registry.at(registry.find("millennia").?).name);
    try std.testing.expectEqual(@as(?Unit.Index, null), registry.find("foots"));
}

test "micro sign and greek mu both resolve" {
    var registry: Registry = try .init(std.testing.allocator, .{});
    defer registry.deinit();

    const micro = registry.find("\u{00b5}m") orelse return error.TestUnexpectedResult;
    const mu = registry.find("\u{03bc}m") orelse return error.TestUnexpectedResult;
    try std.testing.expectEqual(micro, mu);
    try std.testing.expectEqualStrings("micrometer", registry.at(micro).name);
}

test "placeholder symbols are gone" {
    var registry: Registry = try .init(std.testing.allocator, .{});
    defer registry.deinit();

    try std.testing.expectEqual(@as(?Unit.Index, null), registry.find("___"));
    try std.testing.expectEqualStrings("minute", registry.at(registry.find("min").?).name);
    try std.testing.expectEqualStrings("minim", registry.at(registry.find("minim").?).name);
}

test "metric conversion" {
    var registry: Registry = try .init(std.testing.allocator, .{});
    defer registry.deinit();

    const meter = registry.find("m").?;
    const foot = registry.find("ft").?;
    const micrometer = registry.find("micrometer").?;
    const kilometer = registry.find("km").?;

    try std.testing.expectApproxEqRel(@as(f64, 6.561679790026247), try registry.convert(2, meter, foot), 1e-12);
    try std.testing.expectApproxEqRel(@as(f64, 1e6), try registry.convert(1, meter, micrometer), 1e-12);
    try std.testing.expectApproxEqRel(@as(f64, 1.0), try registry.convert(1000, meter, kilometer), 1e-12);
    try std.testing.expectEqual(@as(f64, 5.0), try registry.convert(5, meter, meter));
}

test "binary data conversion" {
    var registry: Registry = try .init(std.testing.allocator, .{});
    defer registry.deinit();

    const kib = registry.find("KiB").?;
    const mib = registry.find("MiB").?;
    try std.testing.expectApproxEqRel(@as(f64, 1.0), try registry.convert(1024, kib, mib), 1e-12);
}

test "temperature is affine in both directions" {
    var registry: Registry = try .init(std.testing.allocator, .{});
    defer registry.deinit();

    const c = registry.find("C").?;
    const f = registry.find("F").?;
    const k = registry.find("K").?;

    try std.testing.expectApproxEqAbs(@as(f64, 212.0), try registry.convert(100, c, f), 1e-9);
    try std.testing.expectApproxEqAbs(@as(f64, 100.0), try registry.convert(212, f, c), 1e-9);
    try std.testing.expectApproxEqAbs(@as(f64, 373.15), try registry.convert(100, c, k), 1e-9);
    try std.testing.expectApproxEqAbs(@as(f64, 100.0), try registry.convert(373.15, k, c), 1e-9);
    try std.testing.expectApproxEqAbs(@as(f64, 310.9277777777778), try registry.convert(100, f, k), 1e-9);
    try std.testing.expectApproxEqAbs(@as(f64, 100.0), try registry.convert(310.9277777777778, k, f), 1e-9);
}

test "cross-category conversion is rejected" {
    var registry: Registry = try .init(std.testing.allocator, .{});
    defer registry.deinit();

    const meter = registry.find("m").?;
    const kilogram = registry.find("kg").?;
    try std.testing.expectError(error.IncompatibleUnits, registry.convert(2, meter, kilogram));
}

test "compound velocity units" {
    var registry: Registry = try .init(std.testing.allocator, .{});
    defer registry.deinit();

    const kmh = registry.find("km/h").?;
    const mph = registry.find("mph").?;
    const knot = registry.find("kn").?;

    try std.testing.expectApproxEqRel(@as(f64, 62.13711922373339), try registry.convert(100, kmh, mph), 1e-12);
    try std.testing.expectApproxEqRel(@as(f64, 86.89762419006479), try registry.convert(100, mph, knot), 1e-12);
}

test "owned units outlive their source buffer" {
    var registry: Registry = try .init(std.testing.allocator, .{});
    defer registry.deinit();

    var buffer: [3]u8 = "USD".*;
    const index = try registry.addOwned(.{
        .name = &buffer,
        .symbol = &buffer,
        .plural = "USDs",
        .category = .money,
        .scale = 1.0 / 1.09,
    });
    @memset(&buffer, 0);

    try std.testing.expectEqualStrings("USD", registry.at(index).name);
    try std.testing.expectEqualStrings("USD", registry.at(registry.find("usd").?).name);
    try std.testing.expectEqualStrings("USD", registry.at(registry.find("USDs").?).name);
}
