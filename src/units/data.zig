const std = @import("std");
const conversion = @import("../conversion.zig");

pub const Units = [_]conversion.Unit{
    conversion.Unit{ .name = "bit", .plural = "+s", .symbol = "b", .ratio = 1.0, .category = conversion.Category.data },
    conversion.Unit{ .name = "kilobit", .plural = "+s", .symbol = "Kb", .ratio = 1000.0, .category = conversion.Category.data },
    conversion.Unit{ .name = "megabit", .plural = "+s", .symbol = "Mb", .ratio = 1000000.0, .category = conversion.Category.data },
    conversion.Unit{ .name = "gigabit", .plural = "+s", .symbol = "Gb", .ratio = 1000000000.0, .category = conversion.Category.data },
    conversion.Unit{ .name = "terabit", .plural = "+s", .symbol = "Tb", .ratio = 1000000000000.0, .category = conversion.Category.data },
    conversion.Unit{ .name = "petabit", .plural = "+s", .symbol = "Pb", .ratio = 1000000000000000.0, .category = conversion.Category.data },
    conversion.Unit{ .name = "exabit", .plural = "+s", .symbol = "Eb", .ratio = 1000000000000000000.0, .category = conversion.Category.data },
    conversion.Unit{ .name = "zettabit", .plural = "+s", .symbol = "Zb", .ratio = 1000000000000000000000.0, .category = conversion.Category.data },
    conversion.Unit{ .name = "yottabit", .plural = "+s", .symbol = "Yb", .ratio = 1000000000000000000000000.0, .category = conversion.Category.data },
    conversion.Unit{ .name = "byte", .plural = "+s", .symbol = "B", .ratio = 8.0, .category = conversion.Category.data },
    conversion.Unit{ .name = "kilobyte", .plural = "+s", .symbol = "KB", .ratio = 8000.0, .category = conversion.Category.data },
    conversion.Unit{ .name = "megabyte", .plural = "+s", .symbol = "MB", .ratio = 8000000.0, .category = conversion.Category.data },
    conversion.Unit{ .name = "gigabyte", .plural = "+s", .symbol = "GB", .ratio = 8000000000.0, .category = conversion.Category.data },
    conversion.Unit{ .name = "terabyte", .plural = "+s", .symbol = "TB", .ratio = 8000000000000.0, .category = conversion.Category.data },
    conversion.Unit{ .name = "petabyte", .plural = "+s", .symbol = "PB", .ratio = 8000000000000000.0, .category = conversion.Category.data },
    conversion.Unit{ .name = "exabyte", .plural = "+s", .symbol = "EB", .ratio = 8000000000000000000.0, .category = conversion.Category.data },
    conversion.Unit{ .name = "zettabyte", .plural = "+s", .symbol = "ZB", .ratio = 8000000000000000000000.0, .category = conversion.Category.data },
    conversion.Unit{ .name = "yottabyte", .plural = "+s", .symbol = "YB", .ratio = 8000000000000000000000000.0, .category = conversion.Category.data },
    conversion.Unit{ .name = "kibibyte", .plural = "+s", .symbol = "KiB", .ratio = 8192.0, .category = conversion.Category.data },
    conversion.Unit{ .name = "mebibyte", .plural = "+s", .symbol = "MiB", .ratio = 8388608.0, .category = conversion.Category.data },
    conversion.Unit{ .name = "gibibyte", .plural = "+s", .symbol = "GiB", .ratio = 8589934592.0, .category = conversion.Category.data },
    conversion.Unit{ .name = "tebibyte", .plural = "+s", .symbol = "TiB", .ratio = 8796093022208.0, .category = conversion.Category.data },
    conversion.Unit{ .name = "pebibyte", .plural = "+s", .symbol = "PiB", .ratio = 9007199254740992.0, .category = conversion.Category.data },
    conversion.Unit{ .name = "exbibyte", .plural = "+s", .symbol = "EiB", .ratio = 9223372036854776000.0, .category = conversion.Category.data },
    conversion.Unit{ .name = "zebibyte", .plural = "+s", .symbol = "ZiB", .ratio = 9.44473296573929e+21, .category = conversion.Category.data },
    conversion.Unit{ .name = "yobibyte", .plural = "+s", .symbol = "YiB", .ratio = 9.671406556917033e+24, .category = conversion.Category.data },
};

pub const reference_unit = Units[0];

pub fn load(graph: *conversion.ConversionGraph) !void {
    for (0.., Units) |i, unit| {
        try graph.addConversion(Units[i], reference_unit, unit.ratio);
    }
}
