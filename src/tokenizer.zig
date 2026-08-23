const std = @import("std");

const Registry = @import("Registry.zig");
const Unit = @import("Unit.zig");

const Allocator = std.mem.Allocator;

pub const percent = "%";

pub const Operation = enum {
    in,
    to,
    of,
    add,
    sub,
    mul,
    div,
    pow,
};

pub const Token = struct {
    kind: Kind,
    text: []const u8 = "",
    value: f64 = 0,
    unit: ?Unit.Index = null,
    operation: ?Operation = null,

    pub const Kind = enum {
        number,
        unit,
        operator,
        paren_open,
        paren_close,
        command,
        unknown,
    };

    pub fn isPercent(token: Token) bool {
        return token.kind == .unit and std.mem.eql(u8, token.text, percent);
    }
};

const List = std.ArrayList(Token);

const Position = enum { standalone, attached };

pub fn tokenize(gpa: Allocator, registry: *const Registry, argv: []const []const u8) Allocator.Error![]Token {
    var tokens: List = .empty;
    defer tokens.deinit(gpa);

    for (argv) |argument| try scan(gpa, registry, &tokens, argument);

    return finish(gpa, registry, &tokens);
}

pub fn tokenizeText(gpa: Allocator, registry: *const Registry, text: []const u8) Allocator.Error![]Token {
    var tokens: List = .empty;
    defer tokens.deinit(gpa);

    try scan(gpa, registry, &tokens, text);

    return finish(gpa, registry, &tokens);
}

fn finish(gpa: Allocator, registry: *const Registry, tokens: *List) Allocator.Error![]Token {
    foldPhrases(tokens);
    try collapseCompounds(registry, tokens);
    return tokens.toOwnedSlice(gpa);
}

fn scan(gpa: Allocator, registry: *const Registry, tokens: *List, argument: []const u8) Allocator.Error!void {
    var words = std.mem.tokenizeAny(u8, argument, " \t\r\n");
    while (words.next()) |word| try scanWord(gpa, registry, tokens, word);
}

fn scanWord(gpa: Allocator, registry: *const Registry, tokens: *List, word: []const u8) Allocator.Error!void {
    if (isCommand(word)) {
        try tokens.append(gpa, .{ .kind = .command, .text = word });
        return;
    }

    if (classify(registry, word, .standalone)) |token| {
        try tokens.append(gpa, token);
        return;
    }

    var i: usize = 0;
    var position: Position = .standalone;

    while (i < word.len) {
        const rest = word[i..];

        if (rest[0] == '(' or rest[0] == ')') {
            try tokens.append(gpa, .{
                .kind = if (rest[0] == '(') .paren_open else .paren_close,
                .text = rest[0..1],
            });
            i += 1;
            position = .standalone;
            continue;
        }

        if (symbolOperator(rest)) |symbol| {
            try tokens.append(gpa, .{
                .kind = .operator,
                .text = rest[0..symbol.len],
                .operation = symbol.operation,
            });
            i += symbol.len;
            position = .standalone;
            continue;
        }

        if (std.mem.startsWith(u8, rest, percent)) {
            try tokens.append(gpa, .{ .kind = .unit, .text = percent });
            i += percent.len;
            position = .attached;
            continue;
        }

        if (numberEnd(word, i)) |end| {
            const value = std.fmt.parseFloat(f64, word[i..end]) catch break;
            try tokens.append(gpa, .{ .kind = .number, .text = word[i..end], .value = value });
            i = end;
            position = .attached;
            continue;
        }

        const end = termEnd(registry, word, i) orelse break;
        const term = word[i..end];
        const token = classify(registry, term, position) orelse
            Token{ .kind = .unknown, .text = term };

        try tokens.append(gpa, token);
        i = end;
        position = if (token.kind == .unit) .attached else .standalone;
    }

    if (i < word.len) try tokens.append(gpa, .{ .kind = .unknown, .text = word[i..] });
}

fn classify(registry: *const Registry, term: []const u8, position: Position) ?Token {
    if (std.mem.eql(u8, term, percent)) return .{ .kind = .unit, .text = percent };
    if (position == .standalone) {
        if (operationOf(term)) |operation| {
            return .{ .kind = .operator, .text = term, .operation = operation };
        }
    }
    if (registry.find(term)) |unit| return .{ .kind = .unit, .text = term, .unit = unit };
    return null;
}

const Symbol = struct { len: usize, operation: Operation };

fn symbolOperator(text: []const u8) ?Symbol {
    if (std.mem.startsWith(u8, text, "**")) return .{ .len = 2, .operation = .pow };
    if (std.mem.startsWith(u8, text, "\u{00d7}")) return .{ .len = 2, .operation = .mul };
    if (std.mem.startsWith(u8, text, "\u{00f7}")) return .{ .len = 2, .operation = .div };

    return switch (text[0]) {
        '+' => .{ .len = 1, .operation = .add },
        '-' => .{ .len = 1, .operation = .sub },
        '*' => .{ .len = 1, .operation = .mul },
        '/' => .{ .len = 1, .operation = .div },
        '^' => .{ .len = 1, .operation = .pow },
        else => null,
    };
}

fn termEnd(registry: *const Registry, word: []const u8, start: usize) ?usize {
    const end = termByteEnd(word, start);
    if (end == start) return null;

    if (end < word.len and word[end] == '/') {
        const tail = termByteEnd(word, end + 1);
        if (tail > end + 1 and registry.contains(word[start..tail])) return tail;
    }
    return end;
}

fn termByteEnd(word: []const u8, start: usize) usize {
    var i = start;
    while (i < word.len and isTermByte(word[i])) : (i += 1) {
        if (word[i] >= 0x80 and symbolOperator(word[i..]) != null) break;
    }
    return i;
}

fn isTermByte(c: u8) bool {
    return std.ascii.isAlphanumeric(c) or c >= 0x80;
}

fn numberEnd(text: []const u8, start: usize) ?usize {
    var i = start;

    while (i < text.len and std.ascii.isDigit(text[i])) i += 1;

    if (i < text.len and text[i] == '.') {
        i += 1;
        while (i < text.len and std.ascii.isDigit(text[i])) i += 1;
    }
    if (i == start or (i == start + 1 and text[start] == '.')) return null;

    if (i < text.len and (text[i] == 'e' or text[i] == 'E')) {
        var j = i + 1;
        if (j < text.len and (text[j] == '-' or text[j] == '+')) j += 1;
        const exponent_start = j;
        while (j < text.len and std.ascii.isDigit(text[j])) j += 1;
        if (j > exponent_start) i = j;
    }

    return i;
}

const phrases = .{
    .{ &[_][]const u8{ "raised", "to", "the", "power", "of" }, Operation.pow },
    .{ &[_][]const u8{ "to", "the", "power", "of" }, Operation.pow },
    .{ &[_][]const u8{ "divided", "by" }, Operation.div },
    .{ &[_][]const u8{ "multiplied", "by" }, Operation.mul },
};

fn foldPhrases(tokens: *List) void {
    var i: usize = 0;
    next: while (i < tokens.items.len) : (i += 1) {
        inline for (phrases) |phrase| {
            if (startsWithWords(tokens.items[i..], phrase[0])) {
                tokens.items[i] = .{
                    .kind = .operator,
                    .text = phrase[0][0],
                    .operation = phrase[1],
                };
                tokens.replaceRangeAssumeCapacity(i + 1, phrase[0].len - 1, &.{});
                continue :next;
            }
        }
    }
}

fn startsWithWords(tokens: []const Token, words: []const []const u8) bool {
    if (tokens.len < words.len) return false;
    for (tokens[0..words.len], words) |token, word| {
        if (!std.ascii.eqlIgnoreCase(token.text, word)) return false;
    }
    return true;
}

fn collapseCompounds(registry: *const Registry, tokens: *List) Allocator.Error!void {
    if (tokens.items.len < 3) return;

    var i: usize = 0;
    while (i + 2 < tokens.items.len) {
        const left = tokens.items[i];
        const middle = tokens.items[i + 1];
        const right = tokens.items[i + 2];

        const separator = (middle.kind == .unknown and std.ascii.eqlIgnoreCase(middle.text, "per")) or
            (middle.kind == .operator and middle.operation == .div);

        if (left.kind != .unit or right.kind != .unit or !separator) {
            i += 1;
            continue;
        }

        const compound = compoundSymbol(registry, left, right) orelse {
            i += 1;
            continue;
        };

        tokens.items[i] = .{
            .kind = .unit,
            .text = registry.at(compound).symbol,
            .unit = compound,
        };
        tokens.replaceRangeAssumeCapacity(i + 1, 2, &.{});
    }
}

fn compoundSymbol(registry: *const Registry, left: Token, right: Token) ?Unit.Index {
    const numerator = registry.at(left.unit orelse return null);
    const denominator = registry.at(right.unit orelse return null);

    var top: [max_spellings][]const u8 = undefined;
    var bottom: [max_spellings][]const u8 = undefined;

    for (spellings(numerator, &top)) |above| {
        for (spellings(denominator, &bottom)) |below| {
            if (above.len + 1 + below.len > Registry.max_term_len) continue;

            var buffer: [Registry.max_term_len]u8 = undefined;
            @memcpy(buffer[0..above.len], above);
            buffer[above.len] = '/';
            @memcpy(buffer[above.len + 1 ..][0..below.len], below);

            if (registry.find(buffer[0 .. above.len + 1 + below.len])) |index| return index;
        }
    }

    return null;
}

const max_spellings = 4;

fn spellings(unit: Unit, buffer: *[max_spellings][]const u8) [][]const u8 {
    var len: usize = 0;
    if (unit.symbol.len > 0) {
        buffer[len] = unit.symbol;
        len += 1;
    }
    for (unit.aliases) |alias| {
        if (len == buffer.len) break;
        buffer[len] = alias;
        len += 1;
    }
    return buffer[0..len];
}

fn isCommand(text: []const u8) bool {
    if (text.len < 2 or text[0] != '-') return false;
    for (text) |c| {
        if (std.ascii.isDigit(c)) return false;
    }
    return true;
}

fn operationOf(text: []const u8) ?Operation {
    if (text.len == 1) return switch (text[0]) {
        '+' => .add,
        '-' => .sub,
        '*' => .mul,
        '/' => .div,
        '^' => .pow,
        'x', 'X' => .mul,
        else => null,
    };

    const words = .{
        .{ "in", Operation.in },
        .{ "to", Operation.to },
        .{ "of", Operation.of },
        .{ "plus", Operation.add },
        .{ "minus", Operation.sub },
        .{ "times", Operation.mul },
        .{ "by", Operation.div },
        .{ "divided", Operation.div },
        .{ "multiplied", Operation.mul },
        .{ "power", Operation.pow },
    };

    inline for (words) |entry| {
        if (std.ascii.eqlIgnoreCase(text, entry[0])) return entry[1];
    }
    return null;
}

const testing = std.testing;

fn expectTokens(argv: []const []const u8, expected: []const Token.Kind) !void {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    const tokens = try tokenize(testing.allocator, &registry, argv);
    defer testing.allocator.free(tokens);

    try testing.expectEqual(expected.len, tokens.len);
    for (expected, tokens) |kind, token| try testing.expectEqual(kind, token.kind);
}

test "detached units" {
    try expectTokens(&.{ "2", "m", "in", "ft" }, &.{ .number, .unit, .operator, .unit });
}

test "attached units" {
    try expectTokens(&.{ "2m", "ft" }, &.{ .number, .unit, .unit });
}

test "in is an operator standalone and a unit when attached" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    const detached = try tokenize(testing.allocator, &registry, &.{ "3", "in", "cm" });
    defer testing.allocator.free(detached);
    try testing.expectEqual(Token.Kind.operator, detached[1].kind);

    const attached = try tokenize(testing.allocator, &registry, &.{ "3in", "cm" });
    defer testing.allocator.free(attached);
    try testing.expectEqual(Token.Kind.unit, attached[1].kind);
    try testing.expectEqualStrings("inch", registry.at(attached[1].unit.?).name);
}

test "compound units collapse" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    for ([_][]const []const u8{
        &.{ "100", "km", "per", "hour", "in", "mph" },
        &.{ "100", "km/h", "in", "mph" },
        &.{ "100km/h", "in", "mph" },
    }) |argv| {
        const tokens = try tokenize(testing.allocator, &registry, argv);
        defer testing.allocator.free(tokens);

        try testing.expectEqual(@as(usize, 4), tokens.len);
        try testing.expectEqualStrings("kilometerperhour", registry.at(tokens[1].unit.?).name);
    }
}

test "operator phrases fold into one operator" {
    try expectTokens(&.{ "15.4", "divided", "by", "2" }, &.{ .number, .operator, .number });
    try expectTokens(&.{ "3", "multiplied", "by", "4" }, &.{ .number, .operator, .number });

    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    const tokens = try tokenize(testing.allocator, &registry, &.{ "2", "to", "the", "power", "of", "10" });
    defer testing.allocator.free(tokens);

    try testing.expectEqual(@as(usize, 3), tokens.len);
    try testing.expectEqual(Operation.pow, tokens[1].operation.?);
}

test "flags are commands" {
    try expectTokens(&.{"--help"}, &.{.command});
    try expectTokens(&.{"-v"}, &.{.command});
}

test "a leading sign is an operator" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    const tokens = try tokenize(testing.allocator, &registry, &.{ "-5", "+", "3" });
    defer testing.allocator.free(tokens);

    try testing.expectEqual(@as(usize, 4), tokens.len);
    try testing.expectEqual(Operation.sub, tokens[0].operation.?);
    try testing.expectEqual(@as(f64, 5), tokens[1].value);
    try testing.expectEqual(Operation.add, tokens[2].operation.?);
    try testing.expectEqual(@as(f64, 3), tokens[3].value);
}

test "minus after a number stays an operator" {
    try expectTokens(&.{ "10", "-", "5" }, &.{ .number, .operator, .number });
    try expectTokens(&.{ "10", "-", "-5" }, &.{ .number, .operator, .operator, .number });
}

test "arithmetic without spaces" {
    try expectTokens(&.{"1+1"}, &.{ .number, .operator, .number });
    try expectTokens(&.{"2-1"}, &.{ .number, .operator, .number });
    try expectTokens(&.{"4/2"}, &.{ .number, .operator, .number });
    try expectTokens(&.{"4*3"}, &.{ .number, .operator, .number });
    try expectTokens(&.{"2^4"}, &.{ .number, .operator, .number });
    try expectTokens(&.{"2**4"}, &.{ .number, .operator, .number });
    try expectTokens(&.{"2\u{00d7}4"}, &.{ .number, .operator, .number });
}

test "parentheses" {
    try expectTokens(&.{"(2+1)*3"}, &.{
        .paren_open,
        .number,
        .operator,
        .number,
        .paren_close,
        .operator,
        .number,
    });
    try expectTokens(&.{ "(", "2", "+", "1", ")" }, &.{
        .paren_open,
        .number,
        .operator,
        .number,
        .paren_close,
    });
}

test "exponent notation" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    const tokens = try tokenize(testing.allocator, &registry, &.{ "1.5E-4", "m", "in", "mm" });
    defer testing.allocator.free(tokens);

    try testing.expectApproxEqRel(@as(f64, 1.5e-4), tokens[0].value, 1e-12);
    try testing.expectEqual(Token.Kind.unit, tokens[1].kind);
}

test "exponent marker does not eat a unit symbol" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    const tokens = try tokenize(testing.allocator, &registry, &.{ "3eV", "in", "J" });
    defer testing.allocator.free(tokens);

    try testing.expectEqual(@as(f64, 3), tokens[0].value);
    try testing.expectEqualStrings("electronvolt", registry.at(tokens[1].unit.?).name);
}

test "symbols containing digits are not split" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    for ([_][]const u8{ "mH2O", "inH2O", "N/m\u{b2}" }) |symbol| {
        const tokens = try tokenize(testing.allocator, &registry, &.{ "1", symbol, "in", "Pa" });
        defer testing.allocator.free(tokens);

        try testing.expectEqual(@as(usize, 4), tokens.len);
        try testing.expectEqual(Token.Kind.unit, tokens[1].kind);
        try testing.expectEqualStrings(symbol, registry.at(tokens[1].unit.?).symbol);
    }
}

test "a slash joins a unit only when the pair resolves" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    const joined = try tokenize(testing.allocator, &registry, &.{"1N/m\u{b2}"});
    defer testing.allocator.free(joined);
    try testing.expectEqual(@as(usize, 2), joined.len);
    try testing.expectEqualStrings("N/m\u{b2}", registry.at(joined[1].unit.?).symbol);

    const divided = try tokenize(testing.allocator, &registry, &.{"6m/2"});
    defer testing.allocator.free(divided);
    try testing.expectEqual(@as(usize, 4), divided.len);
    try testing.expectEqual(Operation.div, divided[2].operation.?);
}

test "leading decimal point" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    const tokens = try tokenize(testing.allocator, &registry, &.{ ".5", "m", "in", "cm" });
    defer testing.allocator.free(tokens);

    try testing.expectEqual(@as(usize, 4), tokens.len);
    try testing.expectApproxEqRel(@as(f64, 0.5), tokens[0].value, 1e-12);
}

test "percent" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    const tokens = try tokenize(testing.allocator, &registry, &.{ "10%", "of", "100" });
    defer testing.allocator.free(tokens);

    try testing.expectEqual(@as(usize, 4), tokens.len);
    try testing.expect(tokens[1].isPercent());
}

test "text input matches argv input" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    for ([_]struct { text: []const u8, argv: []const []const u8 }{
        .{ .text = "  2 meters   in feet ", .argv = &.{ "2", "meters", "in", "feet" } },
        .{ .text = "(2 + 1) * 3", .argv = &.{"(2+1)*3"} },
    }) |case| {
        const from_text = try tokenizeText(testing.allocator, &registry, case.text);
        defer testing.allocator.free(from_text);
        const from_argv = try tokenize(testing.allocator, &registry, case.argv);
        defer testing.allocator.free(from_argv);

        try testing.expectEqual(from_argv.len, from_text.len);
        for (from_argv, from_text) |a, b| {
            try testing.expectEqual(a.kind, b.kind);
            try testing.expectEqual(a.unit, b.unit);
            try testing.expectEqual(a.operation, b.operation);
        }
    }
}
