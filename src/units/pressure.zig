const std = @import("std");
const conversion = @import("../conversion.zig");

pub const Units = [_]conversion.Unit{
    conversion.Unit{ .name = "pascal", .plural = "+s", .symbol = "Pa", .ratio = 1.0, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "quectopascal", .plural = "+s", .symbol = "qPa", .ratio = 0.000000000000000000000000000001, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "rontopascal", .plural = "+s", .symbol = "rPa", .ratio = 0.000000000000000000000000001, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "yoctopascal", .plural = "+s", .symbol = "yPa", .ratio = 0.000000000000000000000001, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "zeptopascal", .plural = "+s", .symbol = "zPa", .ratio = 0.000000000000000000001, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "attopascal", .plural = "+s", .symbol = "aPa", .ratio = 0.000000000000000001, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "femtopascal", .plural = "+s", .symbol = "fPa", .ratio = 0.000000000000001, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "picopascal", .plural = "+s", .symbol = "pPa", .ratio = 0.000000000001, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "nanopascal", .plural = "+s", .symbol = "nPa", .ratio = 0.000000001, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "micropascal", .plural = "+s", .symbol = "μPa", .ratio = 0.000001, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "millipascal", .plural = "+s", .symbol = "mPa", .ratio = 0.001, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "centipascal", .plural = "+s", .symbol = "cPa", .ratio = 0.01, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "decipascal", .plural = "+s", .symbol = "dPa", .ratio = 0.1, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "decapascal", .plural = "+s", .symbol = "daPa", .ratio = 10.0, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "hectopascal", .plural = "+s", .symbol = "hPa", .ratio = 100.0, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "kilopascal", .plural = "+s", .symbol = "kPa", .ratio = 1000.0, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "megapascal", .plural = "+s", .symbol = "MPa", .ratio = 1000000.0, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "gigapascal", .plural = "+s", .symbol = "GPa", .ratio = 1000000000.0, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "terapascal", .plural = "+s", .symbol = "TPa", .ratio = 1000000000000.0, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "petapascal", .plural = "+s", .symbol = "PPa", .ratio = 1000000000000000.0, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "exapascal", .plural = "+s", .symbol = "EPa", .ratio = 1000000000000000000.0, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "zettapascal", .plural = "+s", .symbol = "ZPa", .ratio = 1000000000000000000000.0, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "yottapascal", .plural = "+s", .symbol = "YPa", .ratio = 1000000000000000000000000.0, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "ronnapascal", .plural = "+s", .symbol = "RPa", .ratio = 1000000000000000000000000000.0, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "quettapascal", .plural = "+s", .symbol = "QPa", .ratio = 1000000000000000000000000000000.0, .category = conversion.Category.pressure },

    conversion.Unit{ .name = "millibar", .plural = "+s", .symbol = "mbar", .ratio = 100.0, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "centibar", .plural = "+s", .symbol = "cbar", .ratio = 1000.0, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "decibar", .plural = "+s", .symbol = "dbar", .ratio = 10000.0, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "bar", .plural = "+s", .symbol = "bar", .ratio = 100000.0, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "kilobar", .plural = "+s", .symbol = "kbar", .ratio = 100000000.0, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "megabar", .plural = "+s", .symbol = "Mbar", .ratio = 10000000000.0, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "gigabar", .plural = "+s", .symbol = "Gbar", .ratio = 10000000000000.0, .category = conversion.Category.pressure },

    conversion.Unit{ .name = "technicalatmosphere", .plural = "+s", .symbol = "at", .ratio = 98066.5, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "standardatmosphere", .plural = "+s", .symbol = "atm", .ratio = 101325.2738, .category = conversion.Category.pressure },

    conversion.Unit{ .name = "barye", .plural = "+s", .symbol = "Ba", .ratio = 0.1, .category = conversion.Category.pressure },

    conversion.Unit{ .name = "inchofwatercolumn", .plural = "+s", .symbol = "inH20", .ratio = 248.84, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "meterofwatercolumn", .plural = "+s", .symbol = "mmH20", .ratio = 9806.65, .category = conversion.Category.pressure },

    conversion.Unit{ .name = "inchofmercury", .plural = "+s", .symbol = "inHg", .ratio = 3386.38815789, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "meterofmercury", .plural = "+s", .symbol = "mmHg", .ratio = 133.322368421, .category = conversion.Category.pressure },

    conversion.Unit{ .name = "newtonpersquaremeter", .plural = "+s", .symbol = "N/m²", .ratio = 1.0, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "poundforcepersquareinch", .plural = "+s", .symbol = "psi", .ratio = 6894.757, .category = conversion.Category.pressure },
    conversion.Unit{ .name = "torr", .plural = "+s", .symbol = "Torr", .ratio = 133.322368421, .category = conversion.Category.pressure },
};

pub const reference_unit = Units[0];

pub fn load(graph: *conversion.ConversionGraph) !void {
    for (0.., Units) |i, unit| {
        try graph.addConversion(Units[i], reference_unit, unit.ratio);
    }
}
