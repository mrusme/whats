const std = @import("std");
const build_options = @import("build_options");
const conversion = @import("conversion.zig");

const VERSION = build_options.version;

pub fn help(units: *std.MultiArrayList(conversion.Unit)) !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("Usage: whats [OPTION]... NUMBER [UNIT] [OPERATOR] [NUMBER] [UNIT]\n", .{});
    try stdout.print("A command for basic convertion and calculation.\n\n", .{});
    try stdout.print("  -h, --help       display this help and exit\n", .{});
    try stdout.print("  -v, --version    output version information and exit\n", .{});
    try stdout.print("\n", .{});

    try stdout.print("Units:\n", .{});
    try stdout.print("  {s: <8}{s: <24}\n", .{ "Symbol", "Name" });
    try stdout.print("--------------------------------------------------------------------------------\n", .{});
    var temp_category: conversion.Category = conversion.Category.none;
    var category_title: [32]u8 = [_]u8{0} ** 32;
    for (units.items(.name), units.items(.symbol), units.items(.category)) |name, symbol, category| {
        if (temp_category != category) {
            if (temp_category != conversion.Category.none) {
                try stdout.print("\n", .{});
            }
            temp_category = category;
            for (&category_title) |*item| {
                item.* = 0;
            }
            _ = std.ascii.upperString(&category_title, @tagName(category));
            try stdout.print("{s}:\n", .{category_title});
        }
        try stdout.print("  {s: <8}{s: <24}\n", .{ symbol, name });
    }
    try stdout.print("\n", .{});
    try stdout.print("CALCULATION:\n", .{});
    try stdout.print("  {s: <8}{s: <24}\n", .{ "%", "percent" });
    try stdout.print("--------------------------------------------------------------------------------\n", .{});
    try stdout.print("Note:\n", .{});
    try stdout.print("  Symbols are case-sensitive, names are not.\n", .{});
    try stdout.print("\n", .{});

    try stdout.print("Operators:\n", .{});
    try stdout.print("  in: Conversion, e.g. 2m in feet\n", .{});
    try stdout.print("  to: Conversion or calculation, e.g. 2m to feet, 10 to 20\n", .{});
    try stdout.print("  of: Calculation, e.g. 20% of 100, 20 of 100\n", .{});
    try stdout.print("\n", .{});
    try stdout.print("The operator is optional when units are present:\n", .{});
    try stdout.print("  whats 2 m ft\n", .{});
    try stdout.print("  whats 10% 100\n", .{});
    try stdout.print("\n", .{});

    try stdout.print("Examples:\n", .{});
    try stdout.print("  whats 2 meters in feet\n", .{});
    try stdout.print("  whats 1.21 gigawatts in watts\n", .{});
    try stdout.print("  whats 8 kg in grams\n", .{});
    try stdout.print("  whats 1024 KiB in MiB\n", .{});
    try stdout.print("\n", .{});
    try stdout.print("Spaces are optional:\n", .{});
    try stdout.print("  whats 2m ft\n", .{});
    try stdout.print("\n", .{});

    try stdout.print("Report bugs at: https://github.com/mrusme/whats/issues\n", .{});
    try stdout.print("Home page: http://xn--gckvb8fzb.com/projects/whats/\n", .{});
}

pub fn version() !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("whats version {s}\n", .{VERSION});
}
