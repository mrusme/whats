const std = @import("std");
const conversion = @import("../conversion.zig");

pub const Units = [_]conversion.Unit{
    conversion.Unit{ .name = "meter", .plural = "+s", .symbol = "m", .ratio = 1.0, .category = conversion.Category.length },
    conversion.Unit{ .name = "attometer", .plural = "+s", .symbol = "am", .ratio = 0.00000001, .category = conversion.Category.length },
    conversion.Unit{ .name = "femtometer", .plural = "+s", .symbol = "fm", .ratio = 0.0000001, .category = conversion.Category.length },
    conversion.Unit{ .name = "picometer", .plural = "+s", .symbol = "pm", .ratio = 0.000001, .category = conversion.Category.length },
    conversion.Unit{ .name = "nanometer", .plural = "+s", .symbol = "nm", .ratio = 0.00001, .category = conversion.Category.length },
    conversion.Unit{ .name = "micrometer", .plural = "+s", .symbol = "µm", .ratio = 0.0001, .category = conversion.Category.length },
    conversion.Unit{ .name = "millimeter", .plural = "+s", .symbol = "mm", .ratio = 0.001, .category = conversion.Category.length },
    conversion.Unit{ .name = "centimeter", .plural = "+s", .symbol = "cm", .ratio = 0.01, .category = conversion.Category.length },
    conversion.Unit{ .name = "decimeter", .plural = "+s", .symbol = "dm", .ratio = 0.1, .category = conversion.Category.length },
    conversion.Unit{ .name = "decameter", .plural = "+s", .symbol = "dam", .ratio = 10.0, .category = conversion.Category.length },
    conversion.Unit{ .name = "hectometer", .plural = "+s", .symbol = "hm", .ratio = 100.0, .category = conversion.Category.length },
    conversion.Unit{ .name = "kilometer", .plural = "+s", .symbol = "km", .ratio = 1000.0, .category = conversion.Category.length },
    conversion.Unit{ .name = "megameter", .plural = "+s", .symbol = "Mm", .ratio = 10000.0, .category = conversion.Category.length },
    conversion.Unit{ .name = "gigameter", .plural = "+s", .symbol = "Gm", .ratio = 100000.0, .category = conversion.Category.length },
    conversion.Unit{ .name = "terameter", .plural = "+s", .symbol = "Tm", .ratio = 1000000.0, .category = conversion.Category.length },
    conversion.Unit{ .name = "petameter", .plural = "+s", .symbol = "Pm", .ratio = 10000000.0, .category = conversion.Category.length },
    conversion.Unit{ .name = "exameter", .plural = "+s", .symbol = "Em", .ratio = 100000000.0, .category = conversion.Category.length },
    conversion.Unit{ .name = "angstrom", .plural = "+s", .symbol = "Å", .ratio = 0.0000000001, .category = conversion.Category.length },
    conversion.Unit{ .name = "inch", .plural = "+s", .symbol = "in", .ratio = 0.0254, .category = conversion.Category.length },
    conversion.Unit{ .name = "foot", .plural = "feet", .symbol = "ft", .ratio = 0.3048, .category = conversion.Category.length },
    conversion.Unit{ .name = "yard", .plural = "+s", .symbol = "yd", .ratio = 0.9144, .category = conversion.Category.length },
    conversion.Unit{ .name = "mile", .plural = "+s", .symbol = "mi", .ratio = 1609.344, .category = conversion.Category.length },
    conversion.Unit{ .name = "nauticalmile", .plural = "+s", .symbol = "nmi", .ratio = 1852, .category = conversion.Category.length },
    conversion.Unit{ .name = "league", .plural = "+s", .symbol = "lea", .ratio = 4828.032, .category = conversion.Category.length },
    conversion.Unit{ .name = "furlong", .plural = "+s", .symbol = "fur", .ratio = 201.168, .category = conversion.Category.length },
};

pub const reference_unit = Units[0];
pub const meter = Units[0];
pub const attometer = Units[1];
pub const femtometer = Units[2];
pub const picometer = Units[3];
pub const nanometer = Units[4];
pub const micrometer = Units[5];
pub const millimeter = Units[6];
pub const centimeter = Units[7];
pub const decimeter = Units[8];
pub const decameter = Units[9];
pub const hectometer = Units[10];
pub const kilometer = Units[11];
pub const megameter = Units[12];
pub const gigameter = Units[13];
pub const terameter = Units[14];
pub const petameter = Units[15];
pub const exameter = Units[16];
pub const angstrom = Units[17];
pub const inch = Units[18];
pub const foot = Units[19];
pub const yard = Units[20];
pub const mile = Units[21];
pub const nauticalmile = Units[22];
pub const league = Units[23];
pub const furlong = Units[24];

pub fn load(graph: *conversion.ConversionGraph) !void {
    for (0.., Units) |i, unit| {
        try graph.addConversion(Units[i], reference_unit, unit.ratio);
    }
}
