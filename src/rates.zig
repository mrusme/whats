const std = @import("std");
const xml = @import("xml");

const Registry = @import("Registry.zig");
const Unit = @import("Unit.zig");

const Allocator = std.mem.Allocator;
const Io = std.Io;

pub const source_url = "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml";
pub const cache_file_name = "whats-rates.xml";
pub const base_currency = "EUR";

pub const max_document_bytes = 1024 * 1024;

pub const Entry = struct {
    code: []const u8,
    rate: f64,
};

pub const Table = struct {
    entries: []Entry,
    arena: std.heap.ArenaAllocator.State,

    pub fn deinit(table: *Table, gpa: Allocator) void {
        table.arena.promote(gpa).deinit();
        table.* = undefined;
    }

    pub fn get(table: Table, code: []const u8) ?f64 {
        for (table.entries) |entry| {
            if (std.ascii.eqlIgnoreCase(entry.code, code)) return entry.rate;
        }
        return null;
    }
};

pub const ParseError = Allocator.Error || error{MalformedDocument};

pub fn parse(gpa: Allocator, document: []const u8) ParseError!Table {
    var arena: std.heap.ArenaAllocator = .init(gpa);
    errdefer arena.deinit();
    const allocator = arena.allocator();

    var entries: std.ArrayList(Entry) = .empty;

    var static: xml.Reader.Static = .init(gpa, document, .{});
    defer static.deinit();
    const reader = &static.interface;

    while (true) {
        const node = reader.read() catch return error.MalformedDocument;
        switch (node) {
            .eof => break,
            .element_start => {
                if (!std.mem.eql(u8, reader.elementNameNs().local, "Cube")) continue;

                var code: ?[]const u8 = null;
                var rate: ?f64 = null;

                for (0..reader.attributeCount()) |i| {
                    const name = reader.attributeNameNs(i).local;
                    const value = try reader.attributeValue(i);
                    if (std.mem.eql(u8, name, "currency")) {
                        code = try allocator.dupe(u8, value);
                    } else if (std.mem.eql(u8, name, "rate")) {
                        rate = std.fmt.parseFloat(f64, value) catch return error.MalformedDocument;
                    }
                }

                if (code != null and rate != null) {
                    try entries.append(allocator, .{ .code = code.?, .rate = rate.? });
                }
            },
            else => {},
        }
    }

    return .{
        .entries = try entries.toOwnedSlice(allocator),
        .arena = arena.state,
    };
}

pub const LoadError = ParseError || error{Unavailable};

pub const Options = struct {
    max_age: Io.Duration = .fromSeconds(24 * 60 * 60),
    offline: bool = false,
};

pub fn load(gpa: Allocator, io: Io, cache_path: []const u8, options: Options) LoadError!Table {
    const cwd: Io.Dir = .cwd();

    if (!options.offline and isStale(io, cwd, cache_path, options.max_age)) {
        fetch(gpa, io, cwd, cache_path) catch {};
    }

    const document = cwd.readFileAlloc(io, cache_path, gpa, .limited(max_document_bytes)) catch
        return error.Unavailable;
    defer gpa.free(document);

    return parse(gpa, document);
}

pub const FetchError = error{
    RequestFailed,
    WriteFailed,
};

pub fn fetch(gpa: Allocator, io: Io, dir: Io.Dir, path: []const u8) FetchError!void {
    var client: std.http.Client = .{ .allocator = gpa, .io = io };
    defer client.deinit();

    var atomic = dir.createFileAtomic(io, path, .{
        .make_path = true,
        .replace = true,
    }) catch return error.WriteFailed;
    defer atomic.deinit(io);

    var buffer: [4096]u8 = undefined;
    var writer = atomic.file.writer(io, &buffer);

    const response = client.fetch(.{
        .method = .GET,
        .location = .{ .url = source_url },
        .response_writer = &writer.interface,
    }) catch return error.RequestFailed;

    if (response.status.class() != .success) return error.RequestFailed;

    writer.interface.flush() catch return error.WriteFailed;
    atomic.replace(io) catch return error.WriteFailed;
}

pub fn addTo(registry: *Registry, table: Table) Allocator.Error!void {
    const eur = registry.reference(.money) orelse return;

    var plural_buffer: [Registry.max_term_len]u8 = undefined;

    for (table.entries) |entry| {
        if (entry.rate == 0) continue;
        if (registry.contains(entry.code)) continue;
        if (entry.code.len + 1 > plural_buffer.len) continue;

        @memcpy(plural_buffer[0..entry.code.len], entry.code);
        plural_buffer[entry.code.len] = 's';

        const index = try registry.addOwned(.{
            .name = entry.code,
            .symbol = entry.code,
            .plural = plural_buffer[0 .. entry.code.len + 1],
            .category = .money,
            .scale = entry.rate,
            .mode = .offset_then_scale,
        });
        try registry.link(index, eur, registry.at(index).toReference());
    }
}

pub fn mentionsCurrency(registry: *const Registry, argv: []const []const u8) bool {
    for (argv) |argument| {
        var words = std.mem.tokenizeAny(u8, argument, " \t\r\n");
        while (words.next()) |word| {
            if (isUnknownCode(registry, word)) return true;
        }
    }
    return false;
}

fn isUnknownCode(registry: *const Registry, word: []const u8) bool {
    var term = word;
    while (term.len > 0 and !std.ascii.isAlphabetic(term[0])) term = term[1..];
    while (term.len > 0 and !std.ascii.isAlphabetic(term[term.len - 1])) term = term[0 .. term.len - 1];

    if (term.len == 4 and (term[3] == 's' or term[3] == 'S')) term = term[0..3];
    if (term.len != 3) return false;

    for (term) |c| {
        if (!std.ascii.isAlphabetic(c)) return false;
    }
    return !registry.contains(term);
}

pub fn joinPath(buffer: []u8, parts: []const []const u8) ?[]const u8 {
    var len: usize = 0;
    for (parts, 0..) |part, i| {
        if (i > 0) {
            if (len + 1 > buffer.len) return null;
            buffer[len] = Io.Dir.path.sep;
            len += 1;
        }
        if (len + part.len > buffer.len) return null;
        @memcpy(buffer[len..][0..part.len], part);
        len += part.len;
    }
    return buffer[0..len];
}

fn isStale(io: Io, dir: Io.Dir, path: []const u8, max_age: Io.Duration) bool {
    const stat = dir.statFile(io, path, .{}) catch return true;
    const age = stat.mtime.untilNow(io, .real);
    return age.nanoseconds >= max_age.nanoseconds;
}

const testing = std.testing;

const sample =
    \\<?xml version="1.0" encoding="UTF-8"?>
    \\<gesmes:Envelope xmlns:gesmes="http://www.gesmes.org/xml/2002-08-01" xmlns="http://www.ecb.int/vocabulary/2002-08-01/eurofxref">
    \\  <gesmes:subject>Reference rates</gesmes:subject>
    \\  <Cube>
    \\    <Cube time="2026-08-21">
    \\      <Cube currency="USD" rate="1.0873"/>
    \\      <Cube currency="JPY" rate="160.25"/>
    \\      <Cube currency="GBP" rate="0.8532"/>
    \\    </Cube>
    \\  </Cube>
    \\</gesmes:Envelope>
;

test parse {
    var table = try parse(testing.allocator, sample);
    defer table.deinit(testing.allocator);

    try testing.expectEqual(@as(usize, 3), table.entries.len);
    try testing.expectEqualStrings("USD", table.entries[0].code);
    try testing.expectApproxEqRel(@as(f64, 1.0873), table.get("USD").?, 1e-12);
    try testing.expectApproxEqRel(@as(f64, 0.8532), table.get("gbp").?, 1e-12);
    try testing.expectEqual(@as(?f64, null), table.get("CHF"));
}

test "malformed documents are rejected" {
    try testing.expectError(error.MalformedDocument, parse(testing.allocator, "<Cube currency="));
}

test addTo {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    var table = try parse(testing.allocator, sample);
    defer table.deinit(testing.allocator);

    try addTo(&registry, table);

    const usd = registry.find("USD") orelse return error.TestUnexpectedResult;
    const eur = registry.find("EUR") orelse return error.TestUnexpectedResult;

    try testing.expectApproxEqRel(@as(f64, 1.0873), try registry.convert(1, eur, usd), 1e-12);
    try testing.expectApproxEqRel(@as(f64, 1.0), try registry.convert(1.0873, usd, eur), 1e-12);

    const jpy = registry.find("jpy") orelse return error.TestUnexpectedResult;
    try testing.expectApproxEqRel(@as(f64, 160.25 / 1.0873), try registry.convert(1, usd, jpy), 1e-12);
}

test mentionsCurrency {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    try testing.expect(mentionsCurrency(&registry, &.{ "2", "USD", "in", "EUR" }));
    try testing.expect(mentionsCurrency(&registry, &.{ "2USD", "EUR" }));
    try testing.expect(mentionsCurrency(&registry, &.{ "2", "USDs", "in", "EUR" }));
    try testing.expect(!mentionsCurrency(&registry, &.{ "2", "m", "in", "ft" }));
    try testing.expect(!mentionsCurrency(&registry, &.{ "1024", "KiB", "in", "MiB" }));
    try testing.expect(!mentionsCurrency(&registry, &.{ "10", "+", "5" }));
    try testing.expect(mentionsCurrency(&registry, &.{"(100 USD + 50 USD) in EUR"}));
    try testing.expect(!mentionsCurrency(&registry, &.{"(2 m + 30 cm) in ft"}));
}
