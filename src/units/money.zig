const std = @import("std");
const xml = @import("xml");
const kf = @import("known-folders");
const conversion = @import("../conversion.zig");

pub const known_folders_config = .{
    .xdg_on_mac = true,
};

pub fn load(allocator: std.mem.Allocator, graph: *conversion.ConversionGraph) !std.MultiArrayList(conversion.Unit) {
    var units = std.MultiArrayList(conversion.Unit){};

    const eur = conversion.Unit{ .name = "EUR", .plural = "+s", .symbol = "EUR", .ratio = 1.0, .category = conversion.Category.money };
    try units.ensureTotalCapacity(allocator, 1);
    try units.append(allocator, eur);

    const cache_dir = try kf.getPath(allocator, kf.KnownFolder.cache);
    const rates_paths = [_][]const u8{ cache_dir.?, "whats-rates.xml" };
    const rates_file = try std.fs.path.join(allocator, &rates_paths);
    defer {
        allocator.free(cache_dir.?);
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
        try graph.addConversion(unit, eur, unit.ratio);

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
    const alloc = std.heap.page_allocator;

    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    var response_body = std.ArrayList(u8).init(alloc);

    const response = try client.fetch(.{
        .method = .GET,
        .location = .{ .url = url },
        .response_storage = .{ .dynamic = &response_body },
    });

    if (response.status != std.http.Status.ok) {
        return;
    }

    const file = try std.fs.cwd().createFile(file_path, .{ .truncate = true });
    defer file.close();

    try file.writeAll(response_body.items);
}

pub fn parseRates(allocator: std.mem.Allocator, file_path: []const u8) !std.StringHashMap(f64) {
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    var doc = xml.streamingDocument(allocator, file.reader());
    defer doc.deinit();
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

// pub fn convertCurrencyToUSDctsWithRates(
//     rates: std.StringHashMap(f64),
//     cents: i64,
//     curr: []const u8,
// ) !i64 {
//     const rate = rates.get(curr) orelse return error.CurrencyNotAvailable;
//     const usd_rate = rates.get("USD") orelse return error.CurrencyNotAvailable;
//
//     const usd_cents = std.math.roundToEven(f64(cents) * (usd_rate / rate));
//     return @intCast(usd_cents);
// }
//
// pub fn convertCurrencyToUSDcts(
//     allocator: *std.mem.Allocator,
//     cents: i64,
//     curr: []const u8,
// ) !i64 {
//     const rates = try fetchRates(allocator);
//     defer rates.deinit();
//
//     return try convertCurrencyToUSDctsWithRates(rates, cents, curr);
// }
