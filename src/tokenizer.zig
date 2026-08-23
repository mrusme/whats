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
        command,
        unknown,
    };

    pub fn isPercent(token: Token) bool {
        return token.kind == .unit and std.mem.eql(u8, token.text, percent);
    }
};

const List = std.ArrayList(Token);

pub fn tokenize(gpa: Allocator, registry: *const Registry, argv: []const []const u8) Allocator.Error![]Token {
    var tokens: List = .empty;
    defer tokens.deinit(gpa);

    for (argv) |argument| try scan(gpa, registry, &tokens, argument);

    return finish(gpa, registry, &tokens);
}

pub fn tokenizeText(gpa: Allocator, registry: *const Registry, text: []const u8) Allocator.Error![]Token {
    var tokens: List = .empty;
    defer tokens.deinit(gpa);

    var words = std.mem.tokenizeAny(u8, text, " \t\r\n");
    while (words.next()) |word| try scan(gpa, registry, &tokens, word);

    return finish(gpa, registry, &tokens);
}

fn finish(gpa: Allocator, registry: *const Registry, tokens: *List) Allocator.Error![]Token {
    try collapseCompounds(registry, tokens);
    collapseOperators(tokens);
    return tokens.toOwnedSlice(gpa);
}

fn scan(gpa: Allocator, registry: *const Registry, tokens: *List, argument: []const u8) Allocator.Error!void {
    if (argument.len == 0) return;

    if (isCommand(argument)) {
        try tokens.append(gpa, .{ .kind = .command, .text = argument });
        return;
    }

    if (classify(registry, argument)) |token| {
        try tokens.append(gpa, token);
        return;
    }

    const number = scanNumber(argument, signAllowed(tokens.items)) orelse {
        try tokens.append(gpa, .{ .kind = .unknown, .text = argument });
        return;
    };

    if (number.start > 0) {
        try tokens.append(gpa, attachedTerm(registry, argument[0..number.start]));
    }

    try tokens.append(gpa, .{
        .kind = .number,
        .text = argument[number.start..number.end],
        .value = number.value,
    });

    if (number.end < argument.len) {
        try tokens.append(gpa, attachedTerm(registry, argument[number.end..]));
    }
}

fn classify(registry: *const Registry, term: []const u8) ?Token {
    if (std.mem.eql(u8, term, percent)) return .{ .kind = .unit, .text = percent };
    if (operationOf(term)) |operation| return .{ .kind = .operator, .text = term, .operation = operation };
    if (registry.find(term)) |unit| return .{ .kind = .unit, .text = term, .unit = unit };
    return null;
}

fn attachedTerm(registry: *const Registry, term: []const u8) Token {
    if (std.mem.eql(u8, term, percent)) return .{ .kind = .unit, .text = percent };
    if (registry.find(term)) |unit| return .{ .kind = .unit, .text = term, .unit = unit };
    return .{ .kind = .unknown, .text = term };
}

const Number = struct {
    value: f64,
    start: usize,
    end: usize,
};

fn scanNumber(text: []const u8, signed: bool) ?Number {
    var start: usize = 0;
    while (start < text.len) : (start += 1) {
        const end = numberEnd(text, start, signed and start == 0) orelse continue;
        const value = std.fmt.parseFloat(f64, text[start..end]) catch continue;
        return .{ .value = value, .start = start, .end = end };
    }
    return null;
}

fn numberEnd(text: []const u8, start: usize, signed: bool) ?usize {
    var i = start;
    if (signed and i < text.len and (text[i] == '-' or text[i] == '+')) i += 1;

    const digits_start = i;
    while (i < text.len and std.ascii.isDigit(text[i])) i += 1;

    if (i < text.len and text[i] == '.') {
        i += 1;
        while (i < text.len and std.ascii.isDigit(text[i])) i += 1;
    }
    if (i == digits_start or (i == digits_start + 1 and text[digits_start] == '.')) return null;

    if (i < text.len and (text[i] == 'e' or text[i] == 'E')) {
        var j = i + 1;
        if (j < text.len and (text[j] == '-' or text[j] == '+')) j += 1;
        const exponent_start = j;
        while (j < text.len and std.ascii.isDigit(text[j])) j += 1;
        if (j > exponent_start) i = j;
    }

    return i;
}

fn signAllowed(tokens: []const Token) bool {
    const previous = tokens.len;
    if (previous == 0) return true;
    return switch (tokens[previous - 1].kind) {
        .number, .unit => false,
        .operator, .command, .unknown => true,
    };
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

fn collapseOperators(tokens: *List) void {
    if (tokens.items.len <= 1) return;

    var write: usize = 1;
    var read: usize = 1;
    while (read < tokens.items.len) : (read += 1) {
        const current = tokens.items[read];
        const previous = tokens.items[write - 1];
        if (current.kind == .operator and previous.kind == .operator and
            current.operation == previous.operation) continue;
        tokens.items[write] = current;
        write += 1;
    }
    tokens.shrinkRetainingCapacity(write);
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
    }) |argv| {
        const tokens = try tokenize(testing.allocator, &registry, argv);
        defer testing.allocator.free(tokens);

        try testing.expectEqual(@as(usize, 4), tokens.len);
        try testing.expectEqualStrings("kilometerperhour", registry.at(tokens[1].unit.?).name);
    }
}

test "consecutive equal operators collapse" {
    try expectTokens(&.{ "15.4", "divided", "by", "2" }, &.{ .number, .operator, .number });
}

test "flags are commands" {
    try expectTokens(&.{"--help"}, &.{.command});
    try expectTokens(&.{"-v"}, &.{.command});
}

test "negative numbers" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    const tokens = try tokenize(testing.allocator, &registry, &.{ "-5", "+", "3" });
    defer testing.allocator.free(tokens);

    try testing.expectEqual(@as(usize, 3), tokens.len);
    try testing.expectEqual(@as(f64, -5), tokens[0].value);
    try testing.expectEqual(Operation.add, tokens[1].operation.?);
    try testing.expectEqual(@as(f64, 3), tokens[2].value);
}

test "minus after a number stays an operator" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    const tokens = try tokenize(testing.allocator, &registry, &.{ "10", "-", "5" });
    defer testing.allocator.free(tokens);

    try testing.expectEqual(@as(usize, 3), tokens.len);
    try testing.expectEqual(Operation.sub, tokens[1].operation.?);
    try testing.expectEqual(@as(f64, 5), tokens[2].value);
}

test "negative right operand" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    const tokens = try tokenize(testing.allocator, &registry, &.{ "10", "-", "-5" });
    defer testing.allocator.free(tokens);

    try testing.expectEqual(@as(usize, 3), tokens.len);
    try testing.expectEqual(@as(f64, -5), tokens[2].value);
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

    const from_text = try tokenizeText(testing.allocator, &registry, "  2 meters   in feet ");
    defer testing.allocator.free(from_text);
    const from_argv = try tokenize(testing.allocator, &registry, &.{ "2", "meters", "in", "feet" });
    defer testing.allocator.free(from_argv);

    try testing.expectEqual(from_argv.len, from_text.len);
    for (from_argv, from_text) |a, b| {
        try testing.expectEqual(a.kind, b.kind);
        try testing.expectEqual(a.unit, b.unit);
    }
}
