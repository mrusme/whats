const Unit = @import("../Unit.zig");

pub const units = Unit.table(.pressure, &.{
    .{ .name = "pascal", .symbol = "Pa" },
    .{ .name = "quectopascal", .symbol = "qPa", .scale = 1e-30 },
    .{ .name = "rontopascal", .symbol = "rPa", .scale = 1e-27 },
    .{ .name = "yoctopascal", .symbol = "yPa", .scale = 1e-24 },
    .{ .name = "zeptopascal", .symbol = "zPa", .scale = 1e-21 },
    .{ .name = "attopascal", .symbol = "aPa", .scale = 1e-18 },
    .{ .name = "femtopascal", .symbol = "fPa", .scale = 1e-15 },
    .{ .name = "picopascal", .symbol = "pPa", .scale = 1e-12 },
    .{ .name = "nanopascal", .symbol = "nPa", .scale = 1e-9 },
    .{ .name = "micropascal", .symbol = "µPa", .scale = 1e-6 },
    .{ .name = "millipascal", .symbol = "mPa", .scale = 0.001 },
    .{ .name = "centipascal", .symbol = "cPa", .scale = 0.01 },
    .{ .name = "decipascal", .symbol = "dPa", .scale = 0.1 },
    .{ .name = "decapascal", .symbol = "daPa", .scale = 10.0 },
    .{ .name = "hectopascal", .symbol = "hPa", .scale = 100.0 },
    .{ .name = "kilopascal", .symbol = "kPa", .scale = 1000.0 },
    .{ .name = "megapascal", .symbol = "MPa", .scale = 1e6 },
    .{ .name = "gigapascal", .symbol = "GPa", .scale = 1e9 },
    .{ .name = "terapascal", .symbol = "TPa", .scale = 1e12 },
    .{ .name = "petapascal", .symbol = "PPa", .scale = 1e15 },
    .{ .name = "exapascal", .symbol = "EPa", .scale = 1e18 },
    .{ .name = "zettapascal", .symbol = "ZPa", .scale = 1e21 },
    .{ .name = "yottapascal", .symbol = "YPa", .scale = 1e24 },
    .{ .name = "ronnapascal", .symbol = "RPa", .scale = 1e27 },
    .{ .name = "quettapascal", .symbol = "QPa", .scale = 1e30 },

    .{ .name = "millibar", .symbol = "mbar", .scale = 100.0 },
    .{ .name = "centibar", .symbol = "cbar", .scale = 1000.0 },
    .{ .name = "decibar", .symbol = "dbar", .scale = 10000.0 },
    .{ .name = "bar", .symbol = "bar", .scale = 1e5 },
    .{ .name = "kilobar", .symbol = "kbar", .scale = 1e8 },
    .{ .name = "megabar", .symbol = "Mbar", .scale = 1e11 },
    .{ .name = "gigabar", .symbol = "Gbar", .scale = 1e14 },

    .{ .name = "technicalatmosphere", .symbol = "at", .scale = 98066.5 },
    .{ .name = "standardatmosphere", .symbol = "atm", .scale = 101325.0 },

    .{ .name = "barye", .symbol = "Ba", .scale = 0.1 },

    .{ .name = "inchofwatercolumn", .symbol = "inH2O", .scale = 248.84 },
    .{ .name = "meterofwatercolumn", .symbol = "mH2O", .scale = 9806.65 },

    .{ .name = "inchofmercury", .symbol = "inHg", .scale = 3386.38815789 },
    .{ .name = "millimeterofmercury", .symbol = "mmHg", .scale = 133.322368421 },

    .{ .name = "newtonpersquaremeter", .symbol = "N/m²" },
    .{ .name = "poundforcepersquareinch", .symbol = "psi", .scale = 6894.757 },
    .{ .name = "torr", .symbol = "Torr", .scale = 133.322368421 },
});
