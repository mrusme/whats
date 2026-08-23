const std = @import("std");
const whats = @import("whats");

const Writer = std.Io.Writer;

const rule = "-" ** 80;

pub fn usage(writer: *Writer, registry: *const whats.Registry) Writer.Error!void {
    try writer.writeAll(
        \\Usage: whats [OPTION]... NUMBER [UNIT] [OPERATOR] [NUMBER] [UNIT]
        \\A command for basic convertion and calculation.
        \\
        \\  -h, --help       display this help and exit
        \\  -v, --version    output version information and exit
        \\
        \\Units:
        \\  Symbol  Name
        \\
    );
    try writer.print("{s}\n", .{rule});

    try writeUnits(writer, registry);

    try writer.writeAll(
        \\
        \\CALCULATION:
        \\
    );
    try writer.print("  {s: <8}{s}\n", .{ "%", "percent" });
    try writer.print("{s}\n", .{rule});

    try writer.writeAll(
        \\Note:
        \\  Symbols are case-sensitive, names are not.
        \\
        \\Operators:
        \\  in: Conversion, e.g. 2m in feet
        \\  to: Conversion or calculation, e.g. 2m to feet, 10 to 20
        \\  of: Calculation, e.g. 20% of 100, 20 of 100
        \\
        \\Math operators:
        \\  plus, +          Addition, e.g. 1 plus 2, 1 + 2
        \\  minus, -         Subtraction, e.g. 10 minus 6, 10 - 6
        \\  times, x, *      Multiplication, e.g. 3 times 2, 3 x 2
        \\  by, divided, /   Division, e.g. 15 by 3, 15 divided by 3
        \\  power, ^         Exponentiation, e.g. 10 power 4, 10 ^ 4
        \\
        \\The operator is optional when units are present:
        \\  whats 2 m ft
        \\  whats 10% 100
        \\
        \\Examples:
        \\  whats 2 meters in feet
        \\  whats 1.21 gigawatts in watts
        \\  whats 8 kg in grams
        \\  whats 1024 KiB in MiB
        \\  whats 3 times 2
        \\  whats 10 + 5
        \\  whats 15.4 divided by 2
        \\  whats 100 km per hour in mph
        \\
        \\Compound units can be written as:
        \\  whats 100 km/h in mph
        \\  whats 100 mph in knots
        \\
        \\Spaces are optional:
        \\  whats 2m ft
        \\
        \\Numbers may be signed or written in exponent notation:
        \\  whats -5 + 3
        \\  whats 1.5e-4 m in mm
        \\
        \\Report bugs at: https://tty.fail/mrus/whats/issues
        \\Home page: http://xn--gckvb8fzb.com/projects/whats/
        \\
    );
}

pub fn version(writer: *Writer, text: []const u8) Writer.Error!void {
    try writer.print("whats version {s}\n", .{text});
}

fn writeUnits(writer: *Writer, registry: *const whats.Registry) Writer.Error!void {
    var first = true;
    for (std.enums.values(whats.Category)) |category| {
        var printed_header = false;
        for (registry.list()) |unit| {
            if (unit.category != category) continue;
            if (!printed_header) {
                if (!first) try writer.writeByte('\n');
                var title: [32]u8 = undefined;
                const name = @tagName(category);
                try writer.print("{s}:\n", .{std.ascii.upperString(title[0..name.len], name)});
                printed_header = true;
                first = false;
            }
            try writer.print("  {s: <8}{s}\n", .{ unit.symbol, unit.name });
        }
    }
}

test "help output carries no stray NUL bytes" {
    var buffer: [64 * 1024]u8 = undefined;
    var writer: Writer = .fixed(&buffer);

    var registry: whats.Registry = try .init(std.testing.allocator, .{});
    defer registry.deinit();

    try usage(&writer, &registry);

    const text = writer.buffered();
    try std.testing.expect(text.len > 0);
    try std.testing.expectEqual(@as(?usize, null), std.mem.indexOfScalar(u8, text, 0));
    try std.testing.expect(std.mem.indexOf(u8, text, "\nMONEY:\n  EUR     EUR\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, text, "\nLENGTH:\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, text, "___") == null);

    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |line| {
        if (line.len > 0 and line[line.len - 1] == ' ') {
            std.debug.print("trailing whitespace: \"{s}\"\n", .{line});
            return error.TestUnexpectedResult;
        }
    }
}
