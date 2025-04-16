const std = @import("std");
const conversion = @import("../conversion.zig");

pub const Units = [_]conversion.Unit{
    conversion.Unit{ .name = "liter", .plural = "+s", .symbol = "L", .ratio = 1.0, .category = conversion.Category.volume },
    conversion.Unit{ .name = "quectoliter", .plural = "+s", .symbol = "qL", .ratio = 0.000000000000000000000000000001, .category = conversion.Category.volume },
    conversion.Unit{ .name = "rontoliter", .plural = "+s", .symbol = "rL", .ratio = 0.000000000000000000000000001, .category = conversion.Category.volume },
    conversion.Unit{ .name = "yoctoliter", .plural = "+s", .symbol = "yL", .ratio = 0.000000000000000000000001, .category = conversion.Category.volume },
    conversion.Unit{ .name = "zeptoliter", .plural = "+s", .symbol = "zL", .ratio = 0.000000000000000000001, .category = conversion.Category.volume },
    conversion.Unit{ .name = "attoliter", .plural = "+s", .symbol = "aL", .ratio = 0.000000000000000001, .category = conversion.Category.volume },
    conversion.Unit{ .name = "femtoliter", .plural = "+s", .symbol = "fL", .ratio = 0.000000000000001, .category = conversion.Category.volume },
    conversion.Unit{ .name = "picoliter", .plural = "+s", .symbol = "pL", .ratio = 0.000000000001, .category = conversion.Category.volume },
    conversion.Unit{ .name = "nanoliter", .plural = "+s", .symbol = "nL", .ratio = 0.000000001, .category = conversion.Category.volume },
    conversion.Unit{ .name = "microliter", .plural = "+s", .symbol = "μL", .ratio = 0.000001, .category = conversion.Category.volume },
    conversion.Unit{ .name = "milliliter", .plural = "+s", .symbol = "mL", .ratio = 0.001, .category = conversion.Category.volume },
    conversion.Unit{ .name = "centiliter", .plural = "+s", .symbol = "cL", .ratio = 0.01, .category = conversion.Category.volume },
    conversion.Unit{ .name = "deciliter", .plural = "+s", .symbol = "dL", .ratio = 0.1, .category = conversion.Category.volume },
    conversion.Unit{ .name = "decaliter", .plural = "+s", .symbol = "daL", .ratio = 10.0, .category = conversion.Category.volume },
    conversion.Unit{ .name = "hectoliter", .plural = "+s", .symbol = "hL", .ratio = 100.0, .category = conversion.Category.volume },
    conversion.Unit{ .name = "kiloliter", .plural = "+s", .symbol = "kL", .ratio = 1000.0, .category = conversion.Category.volume },
    conversion.Unit{ .name = "megaliter", .plural = "+s", .symbol = "ML", .ratio = 1000000.0, .category = conversion.Category.volume },
    conversion.Unit{ .name = "gigaliter", .plural = "+s", .symbol = "GL", .ratio = 1000000000.0, .category = conversion.Category.volume },
    conversion.Unit{ .name = "teraliter", .plural = "+s", .symbol = "TL", .ratio = 1000000000000.0, .category = conversion.Category.volume },
    conversion.Unit{ .name = "petaliter", .plural = "+s", .symbol = "PL", .ratio = 1000000000000000.0, .category = conversion.Category.volume },
    conversion.Unit{ .name = "exaliter", .plural = "+s", .symbol = "EL", .ratio = 1000000000000000000.0, .category = conversion.Category.volume },
    conversion.Unit{ .name = "zettaliter", .plural = "+s", .symbol = "ZL", .ratio = 1000000000000000000000.0, .category = conversion.Category.volume },
    conversion.Unit{ .name = "yottaliter", .plural = "+s", .symbol = "YL", .ratio = 1000000000000000000000000.0, .category = conversion.Category.volume },
    conversion.Unit{ .name = "ronnaliter", .plural = "+s", .symbol = "RL", .ratio = 1000000000000000000000000000.0, .category = conversion.Category.volume },
    conversion.Unit{ .name = "quettaliter", .plural = "+s", .symbol = "QL", .ratio = 1000000000000000000000000000000.0, .category = conversion.Category.volume },

    conversion.Unit{ .name = "minim", .plural = "+s", .symbol = "min", .ratio = 0.000061611519921875, .category = conversion.Category.volume },

    conversion.Unit{ .name = "quart", .plural = "+s", .symbol = "qt", .ratio = 1.1365225, .category = conversion.Category.volume },
    conversion.Unit{ .name = "pint", .plural = "+s", .symbol = "pt", .ratio = 0.56826125, .category = conversion.Category.volume },
    conversion.Unit{ .name = "gallon", .plural = "+s", .symbol = "gal", .ratio = 4.54609, .category = conversion.Category.volume },
    conversion.Unit{ .name = "fluidounce", .plural = "+s", .symbol = "floz", .ratio = 0.0284130625, .category = conversion.Category.volume },

    conversion.Unit{ .name = "usfluiddram", .plural = "+s", .symbol = "fldr", .ratio = 0.0036966911953125, .category = conversion.Category.volume },
    conversion.Unit{ .name = "teaspoon", .plural = "+s", .symbol = "tsp", .ratio = 0.00492892159375, .category = conversion.Category.volume },
    conversion.Unit{ .name = "tablespoon", .plural = "+s", .symbol = "tbsp", .ratio = 0.01478676478125, .category = conversion.Category.volume },
    conversion.Unit{ .name = "uspint", .plural = "+s", .symbol = "uspt", .ratio = 0.473176473, .category = conversion.Category.volume },
    conversion.Unit{ .name = "usquart", .plural = "+s", .symbol = "usqt", .ratio = 0.946352946, .category = conversion.Category.volume },
    conversion.Unit{ .name = "uspottle", .plural = "+s", .symbol = "pot", .ratio = 1.892705892, .category = conversion.Category.volume },
    conversion.Unit{ .name = "usgallon", .plural = "+s", .symbol = "usgal", .ratio = 3.785411784, .category = conversion.Category.volume },
    conversion.Unit{ .name = "usfluidounce", .plural = "+s", .symbol = "usfloz", .ratio = 0.0295735295625, .category = conversion.Category.volume },
    conversion.Unit{ .name = "uscup", .plural = "+s", .symbol = "c", .ratio = 0.2365882365, .category = conversion.Category.volume },
    conversion.Unit{ .name = "usshot", .plural = "+s", .symbol = "jig", .ratio = 0.04436029434375, .category = conversion.Category.volume },
    conversion.Unit{ .name = "usgill", .plural = "+s", .symbol = "gi", .ratio = 0.11829411825, .category = conversion.Category.volume },
    conversion.Unit{ .name = "barrel", .plural = "+s", .symbol = "bbl", .ratio = 119.240471196, .category = conversion.Category.volume },
    conversion.Unit{ .name = "oilbarrel", .plural = "+s", .symbol = "___", .ratio = 158.987294928, .category = conversion.Category.volume },
    conversion.Unit{ .name = "hogshead", .plural = "+s", .symbol = "___", .ratio = 238.480942392, .category = conversion.Category.volume },
};

pub const reference_unit = Units[0];

pub fn load(graph: *conversion.ConversionGraph) !void {
    for (0.., Units) |i, unit| {
        try graph.addConversion(Units[i], reference_unit, unit.ratio);
    }
}
