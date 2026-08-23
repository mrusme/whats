const std = @import("std");
const build_options = @import("build_options");
const whats = @import("whats");

const help = @import("cli/help.zig");

const Io = std.Io;
const Writer = std.Io.Writer;

const exit_ok = 0;
const exit_failure = 1;

pub fn main(init: std.process.Init) !u8 {
    const gpa = init.gpa;
    const io = init.io;
    const arena = init.arena.allocator();

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_file = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_file.interface;
    defer stdout.flush() catch {};

    const argv = try arguments(init.minimal.args, arena);

    var registry: whats.Registry = try .init(gpa, .{});
    defer registry.deinit();

    const asks_for_help = isFlag(argv, "-h") or isFlag(argv, "--help");
    if (asks_for_help or whats.rates.mentionsCurrency(&registry, argv)) {
        loadRates(gpa, io, init.environ_map, &registry);
    }

    const tokens = try whats.tokenize(gpa, &registry, argv);
    defer gpa.free(tokens);

    const task = whats.Task.match(tokens);

    switch (task) {
        .empty => {
            fail(io, "missing operand", .{});
            return exit_failure;
        },
        .command => |flag| {
            if (std.mem.eql(u8, flag, "-h") or std.mem.eql(u8, flag, "--help")) {
                try help.usage(stdout, &registry);
                return exit_ok;
            }
            if (std.mem.eql(u8, flag, "-v") or std.mem.eql(u8, flag, "--version")) {
                try help.version(stdout, build_options.version);
                return exit_ok;
            }
            fail(io, "unrecognized option '{s}'", .{flag});
            return exit_failure;
        },
        .query => {
            const result = task.evaluate(&registry) catch |err| {
                switch (err) {
                    error.IncompatibleUnits => fail(io, "cannot convert between those units", .{}),
                    error.UnknownUnit => fail(io, "unknown unit", .{}),
                    error.UnsupportedTask => fail(io, "unsupported operation", .{}),
                    error.UnexpectedToken => fail(io, "unrecognized input", .{}),
                    error.UnexpectedEnd => fail(io, "incomplete expression", .{}),
                    error.UnbalancedParenthesis => fail(io, "unbalanced parentheses", .{}),
                    error.ExpressionTooDeep => fail(io, "expression nested too deeply", .{}),
                    error.UnitMismatch => fail(io, "cannot mix a plain number with a unit", .{}),
                    error.UnitNotAllowed => fail(io, "that operation cannot take a unit", .{}),
                    error.PercentNotAllowed => fail(io, "percent cannot be used there", .{}),
                    error.OutOfMemory => return err,
                }
                return exit_failure;
            };
            try print(stdout, result);
            return exit_ok;
        },
    }
}

fn arguments(args: std.process.Args, arena: std.mem.Allocator) ![]const []const u8 {
    const raw = try args.toSlice(arena);
    if (raw.len <= 1) return &.{};

    const argv = try arena.alloc([]const u8, raw.len - 1);
    for (argv, raw[1..]) |*slot, argument| slot.* = argument;
    return argv;
}

fn isFlag(argv: []const []const u8, flag: []const u8) bool {
    for (argv) |argument| {
        if (std.mem.eql(u8, argument, flag)) return true;
    }
    return false;
}

fn loadRates(
    gpa: std.mem.Allocator,
    io: Io,
    environ: *const std.process.Environ.Map,
    registry: *whats.Registry,
) void {
    var buffer: [Io.Dir.max_path_bytes]u8 = undefined;
    const path = cachePath(&buffer, environ) orelse {
        warn(io, "currency rates unavailable (no cache directory)", .{});
        return;
    };

    var table = whats.rates.load(gpa, io, path, .{}) catch |err| {
        warn(io, "currency rates unavailable ({t})", .{err});
        return;
    };
    defer table.deinit(gpa);

    whats.rates.addTo(registry, table) catch |err| {
        warn(io, "currency rates unavailable ({t})", .{err});
    };
}

fn cachePath(buffer: []u8, environ: *const std.process.Environ.Map) ?[]const u8 {
    const name = whats.rates.cache_file_name;

    if (nonEmpty(environ.get("XDG_CACHE_HOME"))) |dir| {
        return whats.rates.joinPath(buffer, &.{ dir, name });
    }
    if (nonEmpty(environ.get("LOCALAPPDATA"))) |dir| {
        return whats.rates.joinPath(buffer, &.{ dir, name });
    }
    if (nonEmpty(environ.get("HOME"))) |home| {
        return whats.rates.joinPath(buffer, &.{ home, ".cache", name });
    }
    return null;
}

fn nonEmpty(value: ?[]const u8) ?[]const u8 {
    const text = value orelse return null;
    return if (text.len > 0) text else null;
}

fn print(writer: *Writer, result: whats.Result) Writer.Error!void {
    switch (result.display) {
        .number => try writer.print("{d}\n", .{result.value}),
        .percentage => try writer.print("{d}%\n", .{result.value}),
        .percentage_change => if (result.value > 0)
            try writer.print("+{d}%\n", .{result.value})
        else
            try writer.print("{d}%\n", .{result.value}),
    }
}

fn fail(io: Io, comptime format: []const u8, args: anytype) void {
    diagnose(io, "whats: " ++ format ++ "\nTry 'whats --help' for more information.\n", args);
}

fn warn(io: Io, comptime format: []const u8, args: anytype) void {
    diagnose(io, "whats: " ++ format ++ "\n", args);
}

fn diagnose(io: Io, comptime format: []const u8, args: anytype) void {
    var buffer: [1024]u8 = undefined;
    const locked = io.lockStderr(&buffer, null) catch return;
    defer io.unlockStderr();

    const writer = &locked.file_writer.interface;
    writer.print(format, args) catch {};
    writer.flush() catch {};
}

const testing = std.testing;

fn expectPrinted(result: whats.Result, expected: []const u8) !void {
    var buffer: [64]u8 = undefined;
    var writer: Writer = .fixed(&buffer);
    try print(&writer, result);
    try testing.expectEqualStrings(expected, writer.buffered());
}

test print {
    try expectPrinted(.{ .value = 6.561679790026247 }, "6.561679790026247\n");
    try expectPrinted(.{ .value = 20, .display = .percentage }, "20%\n");
    try expectPrinted(.{ .value = 100, .display = .percentage_change }, "+100%\n");
    try expectPrinted(.{ .value = -50, .display = .percentage_change }, "-50%\n");
    try expectPrinted(.{ .value = 0, .display = .percentage_change }, "0%\n");
}

test isFlag {
    try testing.expect(isFlag(&.{ "2", "--help" }, "--help"));
    try testing.expect(!isFlag(&.{ "2", "m" }, "--help"));
}
