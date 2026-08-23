const std = @import("std");

const Registry = @import("Registry.zig");
const tokenizer = @import("tokenizer.zig");
const Unit = @import("Unit.zig");

const Token = tokenizer.Token;
const Operation = tokenizer.Operation;

pub const EvaluateError = Registry.ConvertError || error{UnsupportedTask};

pub const Result = struct {
    value: f64,
    unit: ?Unit.Index = null,
    display: Display = .number,

    pub const Display = enum {
        number,
        percentage,
        percentage_change,
    };
};

pub const Task = union(enum) {
    empty,
    command: []const u8,
    convert: Convert,
    calculate: Calculate,

    pub const Convert = struct {
        value: f64,
        from: Unit.Index,
        to: Unit.Index,
    };

    pub const Calculate = struct {
        lhs: f64,
        rhs: f64,
        operation: Operation,
        lhs_is_percent: bool = false,

        pub fn evaluate(calculate: Calculate) EvaluateError!Result {
            const lhs = calculate.lhs;
            const rhs = calculate.rhs;

            return switch (calculate.operation) {
                .to => .{ .value = ((rhs - lhs) / lhs) * 100.0, .display = .percentage_change },
                .of => if (calculate.lhs_is_percent)
                    .{ .value = (lhs / 100.0) * rhs }
                else
                    .{ .value = (lhs / rhs) * 100.0, .display = .percentage },
                .add => .{ .value = lhs + rhs },
                .sub => .{ .value = lhs - rhs },
                .mul => .{ .value = lhs * rhs },
                .div => .{ .value = lhs / rhs },
                .pow => .{ .value = std.math.pow(f64, lhs, rhs) },
                .in => error.UnsupportedTask,
            };
        }
    };

    pub fn match(tokens: []const Token) ?Task {
        if (tokens.len == 0) return .empty;
        if (tokens.len == 1 and tokens[0].kind == .command) return .{ .command = tokens[0].text };

        if (matchConversion(tokens)) |task| return task;
        if (matchPercentage(tokens)) |task| return task;
        if (matchCalculation(tokens)) |task| return task;

        return null;
    }

    pub fn evaluate(task: Task, registry: *Registry) EvaluateError!Result {
        return switch (task) {
            .empty, .command => error.UnsupportedTask,
            .convert => |convert| .{
                .value = try registry.convert(convert.value, convert.from, convert.to),
                .unit = convert.to,
            },
            .calculate => |calculate| calculate.evaluate(),
        };
    }
};

fn matchConversion(tokens: []const Token) ?Task {
    const shape = switch (tokens.len) {
        3 => tokens[0].kind == .number and tokens[1].kind == .unit and tokens[2].kind == .unit,
        4 => tokens[0].kind == .number and tokens[1].kind == .unit and
            tokens[2].kind == .operator and tokens[3].kind == .unit,
        else => false,
    };
    if (!shape) return null;

    const target = tokens[tokens.len - 1];
    if (tokens[1].isPercent() or target.isPercent()) return null;

    return .{ .convert = .{
        .value = tokens[0].value,
        .from = tokens[1].unit orelse return null,
        .to = target.unit orelse return null,
    } };
}

fn matchPercentage(tokens: []const Token) ?Task {
    if (tokens.len != 3 and tokens.len != 4) return null;
    if (tokens[0].kind != .number or !tokens[1].isPercent()) return null;

    const value = tokens[tokens.len - 1];
    if (value.kind != .number) return null;

    const operation: Operation = if (tokens.len == 3)
        .of
    else if (tokens[2].kind == .operator)
        tokens[2].operation.?
    else
        return null;

    return .{ .calculate = .{
        .lhs = tokens[0].value,
        .rhs = value.value,
        .operation = operation,
        .lhs_is_percent = true,
    } };
}

fn matchCalculation(tokens: []const Token) ?Task {
    if (tokens.len != 3) return null;
    if (tokens[0].kind != .number or tokens[1].kind != .operator or tokens[2].kind != .number) return null;

    return .{ .calculate = .{
        .lhs = tokens[0].value,
        .rhs = tokens[2].value,
        .operation = tokens[1].operation.?,
    } };
}

const testing = std.testing;

fn matchArgv(registry: *Registry, argv: []const []const u8) !?Task {
    const tokens = try tokenizer.tokenize(testing.allocator, registry, argv);
    defer testing.allocator.free(tokens);
    return Task.match(tokens);
}

fn evaluateArgv(registry: *Registry, argv: []const []const u8) !Result {
    const task = try matchArgv(registry, argv) orelse return error.TestUnexpectedResult;
    return task.evaluate(registry);
}

test "conversion patterns" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    for ([_][]const []const u8{
        &.{ "2", "m", "in", "ft" },
        &.{ "2", "m", "ft" },
        &.{ "2m", "ft" },
        &.{ "2", "meters", "in", "feet" },
        &.{ "2m", "in", "feet" },
    }) |argv| {
        const result = try evaluateArgv(&registry, argv);
        try testing.expectApproxEqRel(@as(f64, 6.561679790026247), result.value, 1e-12);
        try testing.expectEqual(Result.Display.number, result.display);
    }
}

test "percentage of" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    for ([_][]const []const u8{
        &.{ "10%", "of", "100" },
        &.{ "10%", "100" },
        &.{ "10", "%", "100" },
    }) |argv| {
        const result = try evaluateArgv(&registry, argv);
        try testing.expectApproxEqAbs(@as(f64, 10.0), result.value, 1e-12);
        try testing.expectEqual(Result.Display.number, result.display);
    }
}

test "share of" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    const result = try evaluateArgv(&registry, &.{ "20", "of", "100" });
    try testing.expectApproxEqAbs(@as(f64, 20.0), result.value, 1e-12);
    try testing.expectEqual(Result.Display.percentage, result.display);
}

test "percentage change" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    const result = try evaluateArgv(&registry, &.{ "10", "to", "20" });
    try testing.expectApproxEqAbs(@as(f64, 100.0), result.value, 1e-12);
    try testing.expectEqual(Result.Display.percentage_change, result.display);
}

test "arithmetic" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    const cases = [_]struct { argv: []const []const u8, want: f64 }{
        .{ .argv = &.{ "3", "times", "2" }, .want = 6 },
        .{ .argv = &.{ "3", "x", "2" }, .want = 6 },
        .{ .argv = &.{ "10", "+", "5" }, .want = 15 },
        .{ .argv = &.{ "10", "minus", "6" }, .want = 4 },
        .{ .argv = &.{ "15.4", "divided", "by", "2" }, .want = 7.7 },
        .{ .argv = &.{ "10", "^", "4" }, .want = 10000 },
        .{ .argv = &.{ "-5", "+", "3" }, .want = -2 },
        .{ .argv = &.{ "10", "-", "-5" }, .want = 15 },
    };

    for (cases) |case| {
        const result = try evaluateArgv(&registry, case.argv);
        try testing.expectApproxEqAbs(case.want, result.value, 1e-9);
    }
}

test "empty and command" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    const empty = try matchArgv(&registry, &.{}) orelse return error.TestUnexpectedResult;
    try testing.expectEqual(Task.empty, empty);

    const command = try matchArgv(&registry, &.{"--help"}) orelse return error.TestUnexpectedResult;
    try testing.expectEqualStrings("--help", command.command);
}

test "unrecognised input does not match" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    for ([_][]const []const u8{
        &.{"gibberish"},
        &.{ "2", "m", "in" },
        &.{ "2", "flurbles", "in", "ft" },
        &.{ "1", "2", "3", "4", "5" },
    }) |argv| {
        try testing.expectEqual(@as(?Task, null), try matchArgv(&registry, argv));
    }
}

test "incompatible units are rejected" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    try testing.expectError(error.IncompatibleUnits, evaluateArgv(&registry, &.{ "2", "m", "in", "kg" }));
}

test "exponent notation converts" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    const result = try evaluateArgv(&registry, &.{ "1e3", "m", "in", "km" });
    try testing.expectApproxEqRel(@as(f64, 1.0), result.value, 1e-12);
}
