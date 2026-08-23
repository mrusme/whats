const std = @import("std");

const task = @import("task.zig");
const tokenizer = @import("tokenizer.zig");

const Allocator = std.mem.Allocator;

pub const Registry = @import("Registry.zig");
pub const Unit = @import("Unit.zig");
pub const Category = Unit.Category;
pub const rates = @import("rates.zig");

pub const Token = tokenizer.Token;
pub const Operation = tokenizer.Operation;
pub const tokenize = tokenizer.tokenize;
pub const tokenizeText = tokenizer.tokenizeText;
pub const percent = tokenizer.percent;

pub const Task = task.Task;
pub const Result = task.Result;

pub const Error = task.EvaluateError || Allocator.Error || error{Unrecognized};

pub fn eval(gpa: Allocator, registry: *Registry, input: []const u8) Error!Result {
    const tokens = try tokenizeText(gpa, registry, input);
    defer gpa.free(tokens);
    return run(registry, tokens);
}

pub fn evalArgv(gpa: Allocator, registry: *Registry, argv: []const []const u8) Error!Result {
    const tokens = try tokenize(gpa, registry, argv);
    defer gpa.free(tokens);
    return run(registry, tokens);
}

fn run(registry: *Registry, tokens: []const Token) Error!Result {
    const matched = Task.match(tokens) orelse return error.Unrecognized;
    return matched.evaluate(registry);
}

test {
    std.testing.refAllDecls(@This());
    _ = task;
    _ = tokenizer;
}

test eval {
    var registry: Registry = try .init(std.testing.allocator, .{});
    defer registry.deinit();

    const feet = try eval(std.testing.allocator, &registry, "2 meters in feet");
    try std.testing.expectApproxEqRel(@as(f64, 6.561679790026247), feet.value, 1e-12);

    const watts = try eval(std.testing.allocator, &registry, "1.21 gigawatts in watts");
    try std.testing.expectApproxEqRel(@as(f64, 1.21e9), watts.value, 1e-12);

    try std.testing.expectError(error.Unrecognized, eval(std.testing.allocator, &registry, "gibberish"));
}

test evalArgv {
    var registry: Registry = try .init(std.testing.allocator, .{});
    defer registry.deinit();

    const grams = try evalArgv(std.testing.allocator, &registry, &.{ "8", "kg", "in", "grams" });
    try std.testing.expectApproxEqRel(@as(f64, 8000.0), grams.value, 1e-12);
}
