const std = @import("std");

const Registry = @import("Registry.zig");
const tokenizer = @import("tokenizer.zig");
const Unit = @import("Unit.zig");

const Operation = tokenizer.Operation;
const Token = tokenizer.Token;

const Parser = @This();

pub const max_depth = 128;

pub const Error = Registry.ConvertError || error{
    UnexpectedToken,
    UnexpectedEnd,
    UnbalancedParenthesis,
    ExpressionTooDeep,
    UnitMismatch,
    UnitNotAllowed,
    PercentNotAllowed,
};

pub const Result = struct {
    value: f64,
    unit: ?Unit.Index = null,
    display: Display = .number,

    pub const Display = enum {
        number,
        percentage,
        percentage_change,
    };

    pub fn isPercent(result: Result) bool {
        return result.display != .number;
    }
};

const Binding = struct { left: u8, right: u8 };

const unary_binding = 9;

tokens: []const Token,
registry: *Registry,
pos: usize = 0,
depth: u32 = 0,

pub fn evaluate(registry: *Registry, tokens: []const Token) Error!Result {
    var parser: Parser = .{ .tokens = tokens, .registry = registry };

    const result = try parser.expression(0);
    if (parser.peek()) |token| {
        if (token.kind == .paren_close) return error.UnbalancedParenthesis;
        return error.UnexpectedToken;
    }
    return result;
}

fn binding(operation: Operation) Binding {
    return switch (operation) {
        .in, .to => .{ .left = 1, .right = 2 },
        .add, .sub => .{ .left = 3, .right = 4 },
        .of => .{ .left = 5, .right = 6 },
        .mul, .div => .{ .left = 7, .right = 8 },
        .pow => .{ .left = 11, .right = 10 },
    };
}

fn expression(parser: *Parser, min_binding: u8) Error!Result {
    if (parser.depth == max_depth) return error.ExpressionTooDeep;
    parser.depth += 1;
    defer parser.depth -= 1;

    var left = try parser.prefix();

    while (parser.peek()) |token| {
        switch (token.kind) {
            .unit => {
                if (binding(.in).left < min_binding) break;
                parser.pos += 1;
                left = try parser.attachUnit(left, token);
            },
            .operator => {
                const operation = token.operation.?;
                const bind = binding(operation);
                if (bind.left < min_binding) break;
                parser.pos += 1;
                left = try parser.applyOperator(operation, bind.right, left);
            },
            .number => {
                const bind = binding(.of);
                if (!left.isPercent() or bind.left < min_binding) break;
                left = try share(parser.registry, left, try parser.expression(bind.right));
            },
            else => break,
        }
    }

    return left;
}

fn prefix(parser: *Parser) Error!Result {
    const token = parser.peek() orelse return error.UnexpectedEnd;

    const sign: f64 = switch (token.kind) {
        .operator => switch (token.operation.?) {
            .add => 1,
            .sub => -1,
            else => return error.UnexpectedToken,
        },
        else => return parser.primary(),
    };

    parser.pos += 1;
    const operand = try parser.expression(unary_binding);
    return like(operand, sign * operand.value);
}

fn primary(parser: *Parser) Error!Result {
    const token = parser.peek() orelse return error.UnexpectedEnd;
    parser.pos += 1;

    switch (token.kind) {
        .number => {
            const next = parser.peek() orelse return .{ .value = token.value };
            if (next.kind != .unit) return .{ .value = token.value };

            parser.pos += 1;
            if (next.isPercent()) return .{ .value = token.value, .display = .percentage };
            return .{ .value = token.value, .unit = next.unit.? };
        },
        .paren_open => {
            const inner = try parser.expression(0);
            const close = parser.peek() orelse return error.UnbalancedParenthesis;
            if (close.kind != .paren_close) return error.UnexpectedToken;
            parser.pos += 1;
            return inner;
        },
        else => return error.UnexpectedToken,
    }
}

fn applyOperator(parser: *Parser, operation: Operation, right_binding: u8, left: Result) Error!Result {
    switch (operation) {
        .in, .to => {
            const token = parser.peek() orelse return error.UnexpectedEnd;
            if (token.kind == .unit) {
                parser.pos += 1;
                return parser.attachUnit(left, token);
            }
            if (operation == .in) return error.UnexpectedToken;
            return change(parser.registry, left, try parser.expression(right_binding));
        },
        else => {
            const right = try parser.expression(right_binding);
            return combine(parser.registry, operation, left, right);
        },
    }
}

fn attachUnit(parser: *Parser, left: Result, token: Token) Error!Result {
    if (token.isPercent()) {
        if (left.isPercent() or left.unit != null) return error.PercentNotAllowed;
        return ratio(left.value);
    }

    if (left.isPercent()) return error.PercentNotAllowed;
    const source = left.unit orelse return error.UnitMismatch;
    const target = token.unit.?;

    return .{
        .value = try parser.registry.convert(left.value, source, target),
        .unit = target,
    };
}

fn combine(registry: *Registry, operation: Operation, left: Result, right: Result) Error!Result {
    return switch (operation) {
        .add, .sub => additive(registry, operation, left, right),
        .mul => multiply(left, right),
        .div => divide(registry, left, right),
        .pow => power(left, right),
        .of => share(registry, left, right),
        .in, .to => unreachable,
    };
}

fn additive(registry: *Registry, operation: Operation, left: Result, right: Result) Error!Result {
    const sign: f64 = if (operation == .sub) -1 else 1;

    if (right.isPercent() and !left.isPercent()) {
        return like(left, left.value + sign * left.value * right.value / 100);
    }

    const target = try alignRight(registry, left, right);
    return like(left, left.value + sign * target);
}

fn multiply(left: Result, right: Result) Error!Result {
    if (left.isPercent()) return like(right, left.value / 100 * right.value);
    if (right.isPercent()) return like(left, left.value * right.value / 100);

    if (left.unit != null and right.unit != null) return error.UnitNotAllowed;
    return .{ .value = left.value * right.value, .unit = left.unit orelse right.unit };
}

fn divide(registry: *Registry, left: Result, right: Result) Error!Result {
    if (right.isPercent()) {
        if (left.isPercent()) return ratio(left.value / right.value * 100);
        return like(left, left.value / (right.value / 100));
    }
    if (left.isPercent()) {
        if (right.unit != null) return error.UnitNotAllowed;
        return ratio(left.value / right.value);
    }
    if (right.unit == null) return .{ .value = left.value / right.value, .unit = left.unit };

    const target = try alignRight(registry, left, right);
    return .{ .value = left.value / target };
}

fn power(left: Result, right: Result) Error!Result {
    if (left.isPercent() or right.isPercent()) return error.PercentNotAllowed;
    if (left.unit != null or right.unit != null) return error.UnitNotAllowed;
    return .{ .value = std.math.pow(f64, left.value, right.value) };
}

fn share(registry: *Registry, left: Result, right: Result) Error!Result {
    if (left.isPercent()) {
        if (right.isPercent()) return ratio(left.value / 100 * right.value);
        return like(right, left.value / 100 * right.value);
    }
    if (right.isPercent()) return error.PercentNotAllowed;

    const target = try alignRight(registry, left, right);
    return ratio(left.value / target * 100);
}

fn change(registry: *Registry, left: Result, right: Result) Error!Result {
    const target = try alignRight(registry, left, right);
    return .{
        .value = (target - left.value) / left.value * 100,
        .display = .percentage_change,
    };
}

fn alignRight(registry: *Registry, left: Result, right: Result) Error!f64 {
    if (left.isPercent() != right.isPercent()) return error.PercentNotAllowed;

    if (left.unit) |target| {
        const source = right.unit orelse return error.UnitMismatch;
        return registry.convert(right.value, source, target);
    }
    if (right.unit != null) return error.UnitMismatch;
    return right.value;
}

fn like(model: Result, value: f64) Result {
    if (!model.isPercent()) return .{ .value = value, .unit = model.unit };
    return ratio(value);
}

fn ratio(value: f64) Result {
    return .{ .value = value, .display = .percentage };
}

fn peek(parser: *const Parser) ?Token {
    if (parser.pos == parser.tokens.len) return null;
    return parser.tokens[parser.pos];
}

const testing = std.testing;

fn evaluateArgv(registry: *Registry, argv: []const []const u8) Error!Result {
    const tokens = try tokenizer.tokenize(testing.allocator, registry, argv);
    defer testing.allocator.free(tokens);
    return evaluate(registry, tokens);
}

fn expectValue(registry: *Registry, argv: []const []const u8, want: f64) !void {
    const result = try evaluateArgv(registry, argv);
    try testing.expectApproxEqAbs(want, result.value, 1e-9);
}

test "precedence and associativity" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    const cases = [_]struct { argv: []const []const u8, want: f64 }{
        .{ .argv = &.{"2+2*4"}, .want = 10 },
        .{ .argv = &.{"2*4+2"}, .want = 10 },
        .{ .argv = &.{"8-3-2"}, .want = 3 },
        .{ .argv = &.{"100/10/2"}, .want = 5 },
        .{ .argv = &.{"2^3^2"}, .want = 512 },
        .{ .argv = &.{"10-2*3"}, .want = 4 },
        .{ .argv = &.{"2*3^2"}, .want = 18 },
    };

    for (cases) |case| try expectValue(&registry, case.argv, case.want);
}

test "parentheses group" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    const cases = [_]struct { argv: []const []const u8, want: f64 }{
        .{ .argv = &.{"(2+1)*3"}, .want = 9 },
        .{ .argv = &.{"((2+1)*3)^2"}, .want = 81 },
        .{ .argv = &.{"2*(3+4)-5"}, .want = 9 },
        .{ .argv = &.{ "(", "2", "+", "1", ")", "*", "3" }, .want = 9 },
        .{ .argv = &.{"-(3+4)"}, .want = -7 },
    };

    for (cases) |case| try expectValue(&registry, case.argv, case.want);
}

test "unary sign binds looser than power" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    const cases = [_]struct { argv: []const []const u8, want: f64 }{
        .{ .argv = &.{"-2^2"}, .want = -4 },
        .{ .argv = &.{"2^-3"}, .want = 0.125 },
        .{ .argv = &.{"-2*3"}, .want = -6 },
        .{ .argv = &.{ "10", "-", "-5" }, .want = 15 },
        .{ .argv = &.{ "-5", "+", "3" }, .want = -2 },
        .{ .argv = &.{"+7"}, .want = 7 },
    };

    for (cases) |case| try expectValue(&registry, case.argv, case.want);
}

test "quantities add and subtract after conversion" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    const sum = try evaluateArgv(&registry, &.{ "2", "m", "+", "30", "cm" });
    try testing.expectApproxEqRel(@as(f64, 2.3), sum.value, 1e-12);
    try testing.expectEqualStrings("meter", registry.at(sum.unit.?).name);

    const feet = try evaluateArgv(&registry, &.{ "2", "m", "+", "30", "cm", "in", "ft" });
    try testing.expectApproxEqRel(@as(f64, 7.545931758530183), feet.value, 1e-12);

    const data = try evaluateArgv(&registry, &.{ "(1", "GB", "+", "500", "MB)", "in", "MB" });
    try testing.expectApproxEqRel(@as(f64, 1500), data.value, 1e-12);
}

test "scaling keeps the unit and dividing quantities drops it" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    const scaled = try evaluateArgv(&registry, &.{ "100", "km/h", "*", "2" });
    try testing.expectApproxEqRel(@as(f64, 200), scaled.value, 1e-12);
    try testing.expectEqualStrings("kilometerperhour", registry.at(scaled.unit.?).name);

    const ratioed = try evaluateArgv(&registry, &.{ "100", "km", "/", "5", "km" });
    try testing.expectApproxEqRel(@as(f64, 20), ratioed.value, 1e-12);
    try testing.expectEqual(@as(?Unit.Index, null), ratioed.unit);
}

test "percent takes part in arithmetic" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    const cases = [_]struct { argv: []const []const u8, want: f64, display: Result.Display }{
        .{ .argv = &.{ "100", "+", "10%" }, .want = 110, .display = .number },
        .{ .argv = &.{ "100", "-", "10%" }, .want = 90, .display = .number },
        .{ .argv = &.{ "100", "*", "10%" }, .want = 10, .display = .number },
        .{ .argv = &.{ "10%", "*", "100" }, .want = 10, .display = .number },
        .{ .argv = &.{ "50", "/", "10%" }, .want = 500, .display = .number },
        .{ .argv = &.{ "10%", "+", "5%" }, .want = 15, .display = .percentage },
        .{ .argv = &.{ "10%", "*", "10%" }, .want = 1, .display = .percentage },
        .{ .argv = &.{ "10%", "/", "5%" }, .want = 200, .display = .percentage },
        .{ .argv = &.{ "10%", "of", "2", "m" }, .want = 0.2, .display = .number },
        .{ .argv = &.{ "50", "cm", "of", "2", "m" }, .want = 25, .display = .percentage },
    };

    for (cases) |case| {
        const result = try evaluateArgv(&registry, case.argv);
        try testing.expectApproxEqAbs(case.want, result.value, 1e-9);
        try testing.expectEqual(case.display, result.display);
    }
}

test "rejected combinations" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    const cases = [_]struct { argv: []const []const u8, want: Error }{
        .{ .argv = &.{ "2", "m", "*", "3", "m" }, .want = error.UnitNotAllowed },
        .{ .argv = &.{ "2", "m", "^", "2" }, .want = error.UnitNotAllowed },
        .{ .argv = &.{ "2", "m", "+", "3", "kg" }, .want = error.IncompatibleUnits },
        .{ .argv = &.{ "2", "m", "+", "3" }, .want = error.UnitMismatch },
        .{ .argv = &.{ "5", "in", "m" }, .want = error.UnitMismatch },
        .{ .argv = &.{ "10%", "+", "5" }, .want = error.PercentNotAllowed },
        .{ .argv = &.{ "10%", "^", "2" }, .want = error.PercentNotAllowed },
        .{ .argv = &.{"(2+1"}, .want = error.UnbalancedParenthesis },
        .{ .argv = &.{"(2+1))"}, .want = error.UnbalancedParenthesis },
        .{ .argv = &.{"2+"}, .want = error.UnexpectedEnd },
        .{ .argv = &.{ "2", "3" }, .want = error.UnexpectedToken },
        .{ .argv = &.{"gibberish"}, .want = error.UnexpectedToken },
    };

    for (cases) |case| try testing.expectError(case.want, evaluateArgv(&registry, case.argv));
}

test "nesting is bounded" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    var deep: [max_depth * 2]u8 = undefined;
    @memset(&deep, '(');

    try testing.expectError(error.ExpressionTooDeep, evaluateArgv(&registry, &.{&deep}));
}
