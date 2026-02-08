const std = @import("std");
const xml = @import("xml");
const conversion = @import("../conversion.zig");

pub fn load(allocator: std.mem.Allocator, graph: *conversion.ConversionGraph) !std.MultiArrayList(conversion.Unit) {
    var units = std.MultiArrayList(conversion.Unit){};

    const eur = conversion.Unit{
        .name = try std.fmt.allocPrint(allocator, "EUR", .{}),
        .plural = try std.fmt.allocPrint(allocator, "EURs", .{}),
        .symbol = try std.fmt.allocPrint(allocator, "EUR", .{}),
        .ratio = 1.0,
        .category = conversion.Category.money,
    };
    try units.ensureTotalCapacity(allocator, 1);
    try units.append(allocator, eur);

    const cache_dir = try getCacheDir(allocator);
    const rates_paths = [_][]const u8{ cache_dir, "whats-rates.xml" };
    const rates_file = try std.fs.path.join(allocator, &rates_paths);
    defer {
        allocator.free(cache_dir);
        allocator.free(rates_file);
    }

    std.log.debug("Using rates file: {s}", .{rates_file});

    const refetch = fileNeedsRefetch(rates_file);
    if (refetch) {
        try fetchRates(allocator, rates_file);
    }
    var rates = try parseRates(allocator, rates_file);
    defer {
        var it = rates.iterator();
        while (it.next()) |entry| {
            allocator.free(entry.key_ptr.*);
        }
        rates.deinit();
    }

    var it = rates.iterator();
    while (it.next()) |entry| {
        const currency = entry.key_ptr.*;
        const rate = entry.value_ptr.*;
        std.log.debug("Currency: {s}, Rate: {d}", .{ currency, rate });

        const name = try std.fmt.allocPrint(allocator, "{s}", .{currency});
        const symbol = try std.fmt.allocPrint(allocator, "{s}", .{currency});
        const plural = try std.fmt.allocPrint(allocator, "{s}s", .{currency});

        const unit = conversion.Unit{ .name = name, .plural = plural, .symbol = symbol, .ratio = rate, .category = conversion.Category.money };
        try graph.addConversion(eur, unit, unit.ratio);

        try units.ensureTotalCapacity(allocator, units.len + 1);
        try units.append(allocator, unit);
    }

    return units;
}

pub fn fileNeedsRefetch(file_path: []const u8) bool {
    const one_day_seconds: i128 = 24 * 60 * 60;

    const stat_result = std.fs.cwd().statFile(file_path);
    if (stat_result) |stat| {
        const modified_time: i128 = stat.mtime;
        const current_time: i128 = @intCast(std.time.timestamp());
        return (current_time - modified_time) > one_day_seconds;
    } else |err| {
        if (err == error.FileNotFound) {
            return true;
        } else {
            return true;
        }
    }
}

pub fn fetchRates(allocator: std.mem.Allocator, file_path: []const u8) !void {
    const url = "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml";

    var client: std.http.Client = .{ .allocator = allocator };
    defer client.deinit();

    const file = try std.fs.cwd().createFile(file_path, .{ .truncate = true });
    defer file.close();

    var buf: [4096]u8 = undefined;
    var file_writer = file.writer(&buf);

    const response = try client.fetch(.{
        .method = .GET,
        .location = .{ .url = url },
        .response_writer = &file_writer.interface,
    });

    try file_writer.interface.flush();

    if (response.status != std.http.Status.ok) {
        return;
    }
}

pub fn parseRates(allocator: std.mem.Allocator, file_path: []const u8) !std.StringHashMap(f64) {
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    const file_content = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(file_content);

    var doc = xml.StaticDocument.init(file_content);
    var reader = doc.reader(allocator, .{});
    defer reader.deinit();

    var rates = std.StringHashMap(f64).init(allocator);

    while (true) {
        const node = reader.read() catch |err| switch (err) {
            error.MalformedXml => {
                std.log.err("MalformedXML", .{});
                return error.MalformedXml;
            },
            else => |other| return other,
        };
        switch (node) {
            .eof => break,
            .element_start => {
                const elem = reader.elementNameNs();
                if (std.mem.eql(u8, elem.local, "Cube")) {
                    var currency: ?[]const u8 = null;
                    var rate_str: ?[]const u8 = null;

                    for (0..reader.reader.attributeCount()) |i| {
                        const attribute_name = reader.attributeNameNs(i);
                        if (std.mem.eql(u8, attribute_name.local, "currency")) {
                            currency = try reader.attributeValue(i);
                        } else if (std.mem.eql(u8, attribute_name.local, "rate")) {
                            rate_str = try reader.attributeValue(i);
                        }
                    }

                    if (currency != null and rate_str != null) {
                        const currency_alloc = try std.fmt.allocPrint(allocator, "{s}", .{currency.?});
                        const rate = try std.fmt.parseFloat(f64, rate_str.?);
                        try rates.put(currency_alloc, rate);
                    }
                }
            },
            else => {},
        }
    }

    return rates;
}

fn getCacheDir(allocator: std.mem.Allocator) ![]const u8 {
    const xdg = std.posix.getenv("XDG_CACHE_HOME");
    if (xdg) |dir| {
        return try allocator.dupe(u8, dir);
    }
    const home = std.posix.getenv("HOME") orelse return error.NoCacheDir;
    return try std.fs.path.join(allocator, &[_][]const u8{ home, ".cache" });
}
