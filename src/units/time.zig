const std = @import("std");
const conversion = @import("../conversion.zig");

pub const Units = .{
    conversion.Unit{ .name = "second", .plural = "+s", .symbol = "s", .ratio = 1.0, .category = conversion.Category.time },
    conversion.Unit{ .name = "quectosecond", .plural = "+s", .symbol = "qs", .ratio = 0.000000000000000000000000000001, .category = conversion.Category.time },
    conversion.Unit{ .name = "rontosecond", .plural = "+s", .symbol = "rs", .ratio = 0.000000000000000000000000001, .category = conversion.Category.time },
    conversion.Unit{ .name = "yoctosecond", .plural = "+s", .symbol = "ys", .ratio = 0.000000000000000000000001, .category = conversion.Category.time },
    conversion.Unit{ .name = "zeptosecond", .plural = "+s", .symbol = "zs", .ratio = 0.000000000000000000001, .category = conversion.Category.time },
    conversion.Unit{ .name = "attosecond", .plural = "+s", .symbol = "as", .ratio = 0.000000000000000001, .category = conversion.Category.time },
    conversion.Unit{ .name = "femtosecond", .plural = "+s", .symbol = "fs", .ratio = 0.000000000000001, .category = conversion.Category.time },
    conversion.Unit{ .name = "picosecond", .plural = "+s", .symbol = "ps", .ratio = 0.000000000001, .category = conversion.Category.time },
    conversion.Unit{ .name = "nanosecond", .plural = "+s", .symbol = "ns", .ratio = 0.000000001, .category = conversion.Category.time },
    conversion.Unit{ .name = "microsecond", .plural = "+s", .symbol = "μs", .ratio = 0.000001, .category = conversion.Category.time },
    conversion.Unit{ .name = "millisecond", .plural = "+s", .symbol = "ms", .ratio = 0.001, .category = conversion.Category.time },
    conversion.Unit{ .name = "centisecond", .plural = "+s", .symbol = "cs", .ratio = 0.01, .category = conversion.Category.time },
    conversion.Unit{ .name = "decisecond", .plural = "+s", .symbol = "ds", .ratio = 0.1, .category = conversion.Category.time },
    conversion.Unit{ .name = "decasecond", .plural = "+s", .symbol = "das", .ratio = 10.0, .category = conversion.Category.time },
    conversion.Unit{ .name = "hectosecond", .plural = "+s", .symbol = "hs", .ratio = 100.0, .category = conversion.Category.time },
    conversion.Unit{ .name = "kilosecond", .plural = "+s", .symbol = "ks", .ratio = 1000.0, .category = conversion.Category.time },
    conversion.Unit{ .name = "megasecond", .plural = "+s", .symbol = "Ms", .ratio = 1000000.0, .category = conversion.Category.time },
    conversion.Unit{ .name = "gigasecond", .plural = "+s", .symbol = "Gs", .ratio = 1000000000.0, .category = conversion.Category.time },
    conversion.Unit{ .name = "terasecond", .plural = "+s", .symbol = "Ts", .ratio = 1000000000000.0, .category = conversion.Category.time },
    conversion.Unit{ .name = "petasecond", .plural = "+s", .symbol = "Ps", .ratio = 1000000000000000.0, .category = conversion.Category.time },
    conversion.Unit{ .name = "exasecond", .plural = "+s", .symbol = "Es", .ratio = 1000000000000000000.0, .category = conversion.Category.time },
    conversion.Unit{ .name = "zettasecond", .plural = "+s", .symbol = "Zs", .ratio = 1000000000000000000000.0, .category = conversion.Category.time },
    conversion.Unit{ .name = "yottasecond", .plural = "+s", .symbol = "Ys", .ratio = 1000000000000000000000000.0, .category = conversion.Category.time },
    conversion.Unit{ .name = "ronnasecond", .plural = "+s", .symbol = "Rs", .ratio = 1000000000000000000000000000.0, .category = conversion.Category.time },
    conversion.Unit{ .name = "quettasecond", .plural = "+s", .symbol = "Qs", .ratio = 1000000000000000000000000000000.0, .category = conversion.Category.time },

    conversion.Unit{ .name = "minute", .plural = "+s", .symbol = "min", .ratio = 60.0, .category = conversion.Category.time },
    conversion.Unit{ .name = "hour", .plural = "+s", .symbol = "hr", .ratio = 3600.0, .category = conversion.Category.time },
    conversion.Unit{ .name = "day", .plural = "+s", .symbol = "d", .ratio = 86400.0, .category = conversion.Category.time },
    conversion.Unit{ .name = "month", .plural = "+s", .symbol = "___", .ratio = 2629800.0, .category = conversion.Category.time },
    conversion.Unit{ .name = "year", .plural = "+s", .symbol = "yr", .ratio = 31557600.0, .category = conversion.Category.time },

    conversion.Unit{ .name = "decade", .plural = "+s", .symbol = "___", .ratio = 315576000.0, .category = conversion.Category.time },
    conversion.Unit{ .name = "century", .plural = "+s", .symbol = "___", .ratio = 3155760000.0, .category = conversion.Category.time },
    conversion.Unit{ .name = "millennium", .plural = "millennia", .symbol = "___", .ratio = 31557600000.0, .category = conversion.Category.time },

    conversion.Unit{ .name = "plancktime", .plural = "+s", .symbol = "𝑡ₚ", .ratio = 5.39e-44, .category = conversion.Category.time },
    conversion.Unit{ .name = "fortnight", .plural = "+s", .symbol = "___", .ratio = 1.21e+6, .category = conversion.Category.time },
    conversion.Unit{ .name = "score", .plural = "+s", .symbol = "___", .ratio = 631152000.0, .category = conversion.Category.time },
};

const second = Units[0];

pub fn load(graph: *conversion.ConversionGraph) !void {
    inline for (Units) |unit| {
        try graph.addConversion(unit, second, unit.ratio);
    }
}
