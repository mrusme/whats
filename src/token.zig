const std = @import("std");
const conversion = @import("conversion.zig");

pub const Operation = enum {
    Undefined,
    In,
    To,
    // Only calculations
    Of, // percentage
    Plus, // +
    Minus, // -
    Times, // *
    By, // /
    Power, // ^
};

pub const TokenKind = enum {
    number,
    unit,
    operator,
    command,
    unknown,
};

pub const Token = struct {
    kind: TokenKind,
    raw: []u8 = "",
    value: ?f64 = null,
    operation: Operation = .Undefined,
};

pub const TokenList = struct {
    allocator: std.mem.Allocator,
    tokens: std.ArrayList(Token),

    pub fn init(allocator: std.mem.Allocator) TokenList {
        return TokenList{
            .allocator = allocator,
            .tokens = .{},
        };
    }

    pub fn deinit(self: *TokenList) void {
        for (self.tokens.items) |tok| {
            if (tok.raw.len > 0) {
                self.allocator.free(tok.raw);
            }
        }
        self.tokens.deinit(self.allocator);
    }

    pub fn tokenize(self: *TokenList, units: *std.MultiArrayList(conversion.Unit)) !void {
        var argsIter = try std.process.ArgIterator.initWithAllocator(self.allocator);
        defer argsIter.deinit();
        _ = argsIter.next(); // skip program name

        while (argsIter.next()) |argStr| {
            try self.tokenizeRaw(argStr, units);
        }

        self.normalize();
    }

    fn tokenizeRaw(self: *TokenList, raw: []const u8, units: *std.MultiArrayList(conversion.Unit)) !void {
        if (raw.len == 0) return;

        // Check for command flags: starts with '-' and contains no digits
        if (isCommand(raw)) {
            try self.appendToken(.{
                .kind = .command,
                .raw = try self.allocCopy(raw),
            });
            return;
        }

        // Find the first digit to split number from term
        var startIndex: usize = 0;
        while (startIndex < raw.len and
            !std.ascii.isDigit(raw[startIndex])) : (startIndex += 1)
        {}

        // No digit found, pure term
        if (startIndex == raw.len) {
            try self.classifyAndAppendStandalone(raw, units);
            return;
        }

        // There's a leading term before the number (e.g. "%3")
        if (startIndex > 0) {
            try self.classifyAndAppendAttached(raw[0..startIndex], units);
        }

        // Parse the numeric portion
        var endIndex = startIndex;
        while (endIndex < raw.len and
            (std.ascii.isDigit(raw[endIndex]) or raw[endIndex] == '.')) : (endIndex += 1)
        {}

        const value = std.fmt.parseFloat(f64, raw[startIndex..endIndex]) catch null;
        try self.appendToken(.{
            .kind = .number,
            .value = value,
        });

        // Trailing term after the number (e.g. "3m" -> "m")
        if (endIndex < raw.len) {
            try self.classifyAndAppendAttached(raw[endIndex..], units);
        }
    }

    /// Classify a standalone term (no number attached).
    /// Priority: % -> operator -> unit -> unknown
    fn classifyAndAppendStandalone(self: *TokenList, raw: []const u8, units: *std.MultiArrayList(conversion.Unit)) !void {
        if (std.mem.eql(u8, raw, "%")) {
            try self.appendToken(.{
                .kind = .unit,
                .raw = try self.allocCopy(raw),
            });
            return;
        }

        const op = getOperation(raw);
        if (op != .Undefined) {
            try self.appendToken(.{
                .kind = .operator,
                .raw = try self.allocCopy(raw),
                .operation = op,
            });
            return;
        }

        if (conversion.isKnownUnit(units, raw)) {
            try self.appendToken(.{
                .kind = .unit,
                .raw = try self.allocCopy(raw),
            });
            return;
        }

        try self.appendToken(.{
            .kind = .unknown,
            .raw = try self.allocCopy(raw),
        });
    }

    /// Classify a term attached to a number (leading or trailing).
    /// Never classify as operator: "3in" means 3 inches, not 3 + operator "in".
    /// Priority: % -> unit -> unknown
    fn classifyAndAppendAttached(self: *TokenList, raw: []const u8, units: *std.MultiArrayList(conversion.Unit)) !void {
        if (std.mem.eql(u8, raw, "%")) {
            try self.appendToken(.{
                .kind = .unit,
                .raw = try self.allocCopy(raw),
            });
            return;
        }

        if (conversion.isKnownUnit(units, raw)) {
            try self.appendToken(.{
                .kind = .unit,
                .raw = try self.allocCopy(raw),
            });
            return;
        }

        try self.appendToken(.{
            .kind = .unknown,
            .raw = try self.allocCopy(raw),
        });
    }

    /// Normalize the token stream.
    /// - Collapses consecutive operators with the same operation (e.g. "divided by" -> single .By)
    /// Future extensions:
    /// - Compound units: [unit("feet"), unknown("per"), unit("second")] -> unit("ft/s")
    fn normalize(self: *TokenList) void {
        if (self.tokens.items.len <= 1) return;
        var write: usize = 1;
        var read: usize = 1;
        while (read < self.tokens.items.len) : (read += 1) {
            const cur = self.tokens.items[read];
            const prev = self.tokens.items[write - 1];
            if (cur.kind == .operator and prev.kind == .operator and cur.operation == prev.operation) {
                if (cur.raw.len > 0) self.allocator.free(cur.raw);
                continue;
            }
            self.tokens.items[write] = cur;
            write += 1;
        }
        self.tokens.shrinkRetainingCapacity(write);
    }

    fn appendToken(self: *TokenList, tok: Token) !void {
        try self.tokens.append(self.allocator, tok);
    }

    fn allocCopy(self: *TokenList, s: []const u8) ![]u8 {
        const copy = try self.allocator.alloc(u8, s.len);
        @memcpy(copy, s);
        return copy;
    }

    pub fn get(self: *TokenList, idx: usize) Token {
        return self.tokens.items[idx];
    }

    pub fn len(self: *TokenList) usize {
        return self.tokens.items.len;
    }

    fn isCommand(s: []const u8) bool {
        if (s.len < 2 or s[0] != '-') return false;
        for (s) |c| {
            if (std.ascii.isDigit(c)) return false;
        }
        return true;
    }

    fn getOperation(s: []const u8) Operation {
        // Single-character symbolic operators
        if (s.len == 1) {
            return switch (s[0]) {
                '+' => .Plus,
                '-' => .Minus,
                '*' => .Times,
                '/' => .By,
                '^' => .Power,
                'x', 'X' => .Times,
                else => .Undefined,
            };
        }
        // Word operators
        if (std.ascii.orderIgnoreCase(s, "in") == .eq) return .In;
        if (std.ascii.orderIgnoreCase(s, "to") == .eq) return .To;
        if (std.ascii.orderIgnoreCase(s, "of") == .eq) return .Of;
        if (std.ascii.orderIgnoreCase(s, "plus") == .eq) return .Plus;
        if (std.ascii.orderIgnoreCase(s, "minus") == .eq) return .Minus;
        if (std.ascii.orderIgnoreCase(s, "times") == .eq) return .Times;
        if (std.ascii.orderIgnoreCase(s, "by") == .eq) return .By;
        if (std.ascii.orderIgnoreCase(s, "divided") == .eq) return .By;
        if (std.ascii.orderIgnoreCase(s, "power") == .eq) return .Power;
        return .Undefined;
    }
};
