const std = @import("std");
const conversion = @import("../conversion.zig");

pub const Units = [_]conversion.Unit{
    conversion.Unit{ .name = "gram", .plural = "+s", .symbol = "g", .ratio = 1.0, .category = conversion.Category.mass },
    conversion.Unit{ .name = "quectogram", .plural = "+s", .symbol = "qg", .ratio = 0.000000000000000000000000000001, .category = conversion.Category.mass },
    conversion.Unit{ .name = "rontogram", .plural = "+s", .symbol = "rg", .ratio = 0.000000000000000000000000001, .category = conversion.Category.mass },
    conversion.Unit{ .name = "yoctogram", .plural = "+s", .symbol = "yg", .ratio = 0.000000000000000000000001, .category = conversion.Category.mass },
    conversion.Unit{ .name = "zeptogram", .plural = "+s", .symbol = "zg", .ratio = 0.000000000000000000001, .category = conversion.Category.mass },
    conversion.Unit{ .name = "attogram", .plural = "+s", .symbol = "ag", .ratio = 0.000000000000000001, .category = conversion.Category.mass },
    conversion.Unit{ .name = "femtogram", .plural = "+s", .symbol = "fg", .ratio = 0.000000000000001, .category = conversion.Category.mass },
    conversion.Unit{ .name = "picogram", .plural = "+s", .symbol = "pg", .ratio = 0.000000000001, .category = conversion.Category.mass },
    conversion.Unit{ .name = "nanogram", .plural = "+s", .symbol = "ng", .ratio = 0.000000001, .category = conversion.Category.mass },
    conversion.Unit{ .name = "microgram", .plural = "+s", .symbol = "μg", .ratio = 0.000001, .category = conversion.Category.mass },
    conversion.Unit{ .name = "milligram", .plural = "+s", .symbol = "mg", .ratio = 0.001, .category = conversion.Category.mass },
    conversion.Unit{ .name = "centigram", .plural = "+s", .symbol = "cg", .ratio = 0.01, .category = conversion.Category.mass },
    conversion.Unit{ .name = "decigram", .plural = "+s", .symbol = "dg", .ratio = 0.1, .category = conversion.Category.mass },
    conversion.Unit{ .name = "decagram", .plural = "+s", .symbol = "dag", .ratio = 10.0, .category = conversion.Category.mass },
    conversion.Unit{ .name = "hectogram", .plural = "+s", .symbol = "hg", .ratio = 100.0, .category = conversion.Category.mass },
    conversion.Unit{ .name = "kilogram", .plural = "+s", .symbol = "kg", .ratio = 1000.0, .category = conversion.Category.mass },
    conversion.Unit{ .name = "megagram", .plural = "+s", .symbol = "Mg", .ratio = 1000000.0, .category = conversion.Category.mass },
    conversion.Unit{ .name = "gigagram", .plural = "+s", .symbol = "Gg", .ratio = 1000000000.0, .category = conversion.Category.mass },
    conversion.Unit{ .name = "teragram", .plural = "+s", .symbol = "Tg", .ratio = 1000000000000.0, .category = conversion.Category.mass },
    conversion.Unit{ .name = "petagram", .plural = "+s", .symbol = "Pg", .ratio = 1000000000000000.0, .category = conversion.Category.mass },
    conversion.Unit{ .name = "exagram", .plural = "+s", .symbol = "Eg", .ratio = 1000000000000000000.0, .category = conversion.Category.mass },
    conversion.Unit{ .name = "zettagram", .plural = "+s", .symbol = "Zg", .ratio = 1000000000000000000000.0, .category = conversion.Category.mass },
    conversion.Unit{ .name = "yottagram", .plural = "+s", .symbol = "Yg", .ratio = 1000000000000000000000000.0, .category = conversion.Category.mass },
    conversion.Unit{ .name = "ronnagram", .plural = "+s", .symbol = "Rg", .ratio = 1000000000000000000000000000.0, .category = conversion.Category.mass },
    conversion.Unit{ .name = "quettagram", .plural = "+s", .symbol = "Qg", .ratio = 1000000000000000000000000000000.0, .category = conversion.Category.mass },

    conversion.Unit{ .name = "grain", .plural = "+s", .symbol = "gr", .ratio = 0.06479891, .category = conversion.Category.mass },
    conversion.Unit{ .name = "drachm", .plural = "+s", .symbol = "dr", .ratio = 1.7718451953125, .category = conversion.Category.mass },
    conversion.Unit{ .name = "ounce", .plural = "+s", .symbol = "oz", .ratio = 28.349523125, .category = conversion.Category.mass },
    conversion.Unit{ .name = "pound", .plural = "+s", .symbol = "lb", .ratio = 453.59237, .category = conversion.Category.mass },
    conversion.Unit{ .name = "stone", .plural = "+s", .symbol = "st", .ratio = 6350.29318, .category = conversion.Category.mass },

    conversion.Unit{ .name = "ton", .plural = "+s", .symbol = "t", .ratio = 1016046.9088, .category = conversion.Category.mass },
    conversion.Unit{ .name = "slug", .plural = "+s", .symbol = "___", .ratio = 14593.90294, .category = conversion.Category.mass },
};

pub const reference_unit = Units[0];

pub fn load(graph: *conversion.ConversionGraph) !void {
    for (0.., Units) |i, unit| {
        try graph.addConversion(Units[i], reference_unit, unit.ratio);
    }
}
