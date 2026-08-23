const std = @import("std");

const Parser = @import("Parser.zig");
const Registry = @import("Registry.zig");
const tokenizer = @import("tokenizer.zig");

const Token = tokenizer.Token;

pub const Result = Parser.Result;

pub const EvaluateError = Parser.Error || error{UnsupportedTask};

pub const Task = union(enum) {
    empty,
    command: []const u8,
    query: []const Token,

    pub fn match(tokens: []const Token) Task {
        if (tokens.len == 0) return .empty;
        if (tokens.len == 1 and tokens[0].kind == .command) return .{ .command = tokens[0].text };
        return .{ .query = tokens };
    }

    pub fn evaluate(task: Task, registry: *Registry) EvaluateError!Result {
        return switch (task) {
            .empty, .command => error.UnsupportedTask,
            .query => |tokens| Parser.evaluate(registry, tokens),
        };
    }
};

const testing = std.testing;

fn evaluateArgv(registry: *Registry, argv: []const []const u8) !Result {
    const tokens = try tokenizer.tokenize(testing.allocator, registry, argv);
    defer testing.allocator.free(tokens);
    return Task.match(tokens).evaluate(registry);
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
        &.{"2m in ft"},
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
        .{ .argv = &.{ "2", "to", "the", "power", "of", "10" }, .want = 1024 },
        .{ .argv = &.{ "-5", "+", "3" }, .want = -2 },
        .{ .argv = &.{ "10", "-", "-5" }, .want = 15 },
        .{ .argv = &.{"2 + 2 * 4"}, .want = 10 },
        .{ .argv = &.{"(2 + 1) * 3"}, .want = 9 },
    };

    for (cases) |case| {
        const result = try evaluateArgv(&registry, case.argv);
        try testing.expectApproxEqAbs(case.want, result.value, 1e-9);
    }
}

test "empty and command" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    const tokens = try tokenizer.tokenize(testing.allocator, &registry, &.{});
    defer testing.allocator.free(tokens);
    try testing.expectEqual(Task.empty, Task.match(tokens));

    const flag = try tokenizer.tokenize(testing.allocator, &registry, &.{"--help"});
    defer testing.allocator.free(flag);
    try testing.expectEqualStrings("--help", Task.match(flag).command);
}

test "unrecognized input is reported" {
    var registry: Registry = try .init(testing.allocator, .{});
    defer registry.deinit();

    for ([_][]const []const u8{
        &.{"gibberish"},
        &.{ "2", "flurbles", "in", "ft" },
        &.{ "1", "2", "3", "4", "5" },
    }) |argv| {
        try testing.expectError(error.UnexpectedToken, evaluateArgv(&registry, argv));
    }

    try testing.expectError(error.UnexpectedEnd, evaluateArgv(&registry, &.{ "2", "m", "in" }));
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
