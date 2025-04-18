const std = @import("std");
const bfstree = @import("bfstree");

pub const Category = enum {
    none,
    data,
    energy,
    length,
    mass,
    money,
    power,
    pressure,
    temperature,
    time,
    volume,
};

pub const Unit = struct {
    name: []const u8,
    plural: []const u8,
    symbol: []const u8,
    category: Category,
    ratio: f64,
};

pub const Conversion = struct {
    from: Unit,
    to: Unit,
    ratio: f64,

    pub fn apply(self: Conversion, x: f64) f64 {
        // It's ugly but it's honest work
        if (std.mem.eql(u8, self.from.name, "celsius") and
            std.mem.eql(u8, self.to.name, "fahrenheit"))
        {
            return x * 1.8 + 32;
        } else if (std.mem.eql(u8, self.from.name, "fahrenheit") and
            std.mem.eql(u8, self.to.name, "celsius"))
        {
            return (x - 32) / 1.8;
        } else if (std.mem.eql(u8, self.from.name, "celsius") and
            std.mem.eql(u8, self.to.name, "kelvin"))
        {
            return x + 273.15;
        } else if (std.mem.eql(u8, self.from.name, "kelvin") and
            std.mem.eql(u8, self.to.name, "celsius"))
        {
            return x - 273.15;
        } else {
            return x * self.ratio;
        }
    }
};

pub const ConversionGraph = struct {
    allocator: std.mem.Allocator,
    tree: bfstree.BFSTree,
    conversions: std.ArrayList(Conversion),

    pub fn init(allocator: std.mem.Allocator) ConversionGraph {
        return ConversionGraph{
            .allocator = allocator,
            .tree = bfstree.BFSTree.init(allocator),
            .conversions = std.ArrayList(Conversion).init(allocator),
        };
    }

    pub fn deinit(self: *ConversionGraph) void {
        self.tree.deinit();
        self.conversions.deinit();
    }

    pub fn addConversion(self: *ConversionGraph, from: Unit, to: Unit, ratio: f64) !void {
        const conv_forward = Conversion{
            .from = from,
            .to = to,
            .ratio = ratio,
        };
        const conv_reverse = Conversion{
            .from = to,
            .to = from,
            .ratio = 1.0 / ratio,
        };

        try self.conversions.append(conv_forward);
        try self.conversions.append(conv_reverse);

        try self.tree.addEdge(bfstree.Edge{ .from = from.name, .to = to.name });
        try self.tree.addEdge(bfstree.Edge{ .from = to.name, .to = from.name });
    }

    pub fn resolveConversion(self: *ConversionGraph, from: *const Unit, to: *const Unit) ![]Conversion {
        const found_path = try self.tree.findPath(from.name, to.name);
        var result = std.ArrayList(Conversion).init(self.allocator);
        if (found_path) |path| {
            defer @constCast(&path).deinit();

            for (path.edges.items) |edge| {
                const conv = try self.lookupConversion(edge.from, edge.to);
                try result.append(conv);
            }
        }

        return result.toOwnedSlice();
    }

    fn lookupConversion(self: *ConversionGraph, from_name: []const u8, to_name: []const u8) !Conversion {
        for (self.conversions.items) |conv| {
            if (std.mem.eql(u8, conv.from.name, from_name) and std.mem.eql(u8, conv.to.name, to_name)) {
                return conv;
            }
        }
        return error.ConversionNotFound;
    }
};
