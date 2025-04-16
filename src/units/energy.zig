const std = @import("std");
const conversion = @import("../conversion.zig");

pub const Units = [_]conversion.Unit{
    conversion.Unit{ .name = "joule", .plural = "+s", .symbol = "J", .ratio = 1.0, .category = conversion.Category.energy },
    conversion.Unit{ .name = "quectojoule", .plural = "+s", .symbol = "qJ", .ratio = 0.000000000000000000000000000001, .category = conversion.Category.energy },
    conversion.Unit{ .name = "rontojoule", .plural = "+s", .symbol = "rJ", .ratio = 0.000000000000000000000000001, .category = conversion.Category.energy },
    conversion.Unit{ .name = "yoctojoule", .plural = "+s", .symbol = "yJ", .ratio = 0.000000000000000000000001, .category = conversion.Category.energy },
    conversion.Unit{ .name = "zeptojoule", .plural = "+s", .symbol = "zJ", .ratio = 0.000000000000000000001, .category = conversion.Category.energy },
    conversion.Unit{ .name = "attojoule", .plural = "+s", .symbol = "aJ", .ratio = 0.000000000000000001, .category = conversion.Category.energy },
    conversion.Unit{ .name = "femtojoule", .plural = "+s", .symbol = "fJ", .ratio = 0.000000000000001, .category = conversion.Category.energy },
    conversion.Unit{ .name = "picojoule", .plural = "+s", .symbol = "pJ", .ratio = 0.000000000001, .category = conversion.Category.energy },
    conversion.Unit{ .name = "nanojoule", .plural = "+s", .symbol = "nJ", .ratio = 0.000000001, .category = conversion.Category.energy },
    conversion.Unit{ .name = "microjoule", .plural = "+s", .symbol = "μJ", .ratio = 0.000001, .category = conversion.Category.energy },
    conversion.Unit{ .name = "millijoule", .plural = "+s", .symbol = "mJ", .ratio = 0.001, .category = conversion.Category.energy },
    conversion.Unit{ .name = "centijoule", .plural = "+s", .symbol = "cJ", .ratio = 0.01, .category = conversion.Category.energy },
    conversion.Unit{ .name = "decijoule", .plural = "+s", .symbol = "dJ", .ratio = 0.1, .category = conversion.Category.energy },
    conversion.Unit{ .name = "decajoule", .plural = "+s", .symbol = "daJ", .ratio = 10.0, .category = conversion.Category.energy },
    conversion.Unit{ .name = "hectojoule", .plural = "+s", .symbol = "hJ", .ratio = 100.0, .category = conversion.Category.energy },
    conversion.Unit{ .name = "kilojoule", .plural = "+s", .symbol = "kJ", .ratio = 1000.0, .category = conversion.Category.energy },
    conversion.Unit{ .name = "megajoule", .plural = "+s", .symbol = "MJ", .ratio = 1000000.0, .category = conversion.Category.energy },
    conversion.Unit{ .name = "gigajoule", .plural = "+s", .symbol = "GJ", .ratio = 1000000000.0, .category = conversion.Category.energy },
    conversion.Unit{ .name = "terajoule", .plural = "+s", .symbol = "TJ", .ratio = 1000000000000.0, .category = conversion.Category.energy },
    conversion.Unit{ .name = "petajoule", .plural = "+s", .symbol = "PJ", .ratio = 1000000000000000.0, .category = conversion.Category.energy },
    conversion.Unit{ .name = "exajoule", .plural = "+s", .symbol = "EJ", .ratio = 1000000000000000000.0, .category = conversion.Category.energy },
    conversion.Unit{ .name = "zettajoule", .plural = "+s", .symbol = "ZJ", .ratio = 1000000000000000000000.0, .category = conversion.Category.energy },
    conversion.Unit{ .name = "yottajoule", .plural = "+s", .symbol = "YJ", .ratio = 1000000000000000000000000.0, .category = conversion.Category.energy },
    conversion.Unit{ .name = "ronnajoule", .plural = "+s", .symbol = "RJ", .ratio = 1000000000000000000000000000.0, .category = conversion.Category.energy },
    conversion.Unit{ .name = "quettajoule", .plural = "+s", .symbol = "QJ", .ratio = 1000000000000000000000000000000.0, .category = conversion.Category.energy },

    conversion.Unit{ .name = "watthour", .plural = "+s", .symbol = "Wh", .ratio = 3600.0, .category = conversion.Category.energy },
    conversion.Unit{ .name = "kilowatthour", .plural = "+s", .symbol = "kWh", .ratio = 3600000.0, .category = conversion.Category.energy },
    conversion.Unit{ .name = "megawatthour", .plural = "+s", .symbol = "MWh", .ratio = 3600000000.0, .category = conversion.Category.energy },
    conversion.Unit{ .name = "gigawatthour", .plural = "+s", .symbol = "GWh", .ratio = 3600000000000.0, .category = conversion.Category.energy },
    conversion.Unit{ .name = "terawatthour", .plural = "+s", .symbol = "TWh", .ratio = 3600000000000000.0, .category = conversion.Category.energy },
    conversion.Unit{ .name = "petawatthour", .plural = "+s", .symbol = "PWh", .ratio = 3600000000000000000.0, .category = conversion.Category.energy },

    conversion.Unit{ .name = "electronvolt", .plural = "+s", .symbol = "eV", .ratio = 1.60218e-19, .category = conversion.Category.energy },

    conversion.Unit{ .name = "calorie", .plural = "+s", .symbol = "cal", .ratio = 4.184, .category = conversion.Category.energy },
};

pub const reference_unit = Units[0];

pub fn load(graph: *conversion.ConversionGraph) !void {
    for (0.., Units) |i, unit| {
        try graph.addConversion(Units[i], reference_unit, unit.ratio);
    }
}
