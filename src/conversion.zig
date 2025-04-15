const std = @import("std");
const bfstree = @import("bfstree");

pub const Category = enum {
    data,
    energy,
    length,
    mass,
    power,
    pressure,
    temperature,
    time,
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
    formula: []const u8,

    pub fn apply(self: Conversion, x: f64) f64 {
        return x * self.ratio;
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
        self.tree.edges.deinit();
        self.conversions.deinit();
    }

    pub fn addConversion(self: *ConversionGraph, from: Unit, to: Unit, ratio: f64) !void {
        const formula_mul = try std.fmt.allocPrint(self.allocator, "x * {}", .{ratio});
        const formula_div = try std.fmt.allocPrint(self.allocator, "x / {}", .{ratio});

        const conv_forward = Conversion{
            .from = from,
            .to = to,
            .ratio = ratio,
            .formula = formula_mul,
        };
        const conv_reverse = Conversion{
            .from = to,
            .to = from,
            .ratio = 1.0 / ratio,
            .formula = formula_div,
        };

        try self.conversions.append(conv_forward);
        try self.conversions.append(conv_reverse);

        try self.tree.addEdge(bfstree.Edge{ .from = from.name, .to = to.name });
        try self.tree.addEdge(bfstree.Edge{ .from = to.name, .to = from.name });
    }

    pub fn resolveConversion(self: *ConversionGraph, from: Unit, to: Unit) ![]Conversion {
        const found_path = try bfstree.findPath(&self.tree, from.name, to.name, self.allocator);
        var result = std.ArrayList(Conversion).init(self.allocator);

        if (found_path) |path| {
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
