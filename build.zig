const std = @import("std");

pub const release_targets: []const std.Target.Query = &.{
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .arm, .os_tag = .linux, .abi = .gnueabihf },
    .{ .cpu_arch = .arm, .os_tag = .linux, .abi = .musleabihf },
    .{ .cpu_arch = .x86, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .x86, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .riscv64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .riscv64, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .powerpc64le, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .powerpc64le, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .s390x, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .s390x, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .loongarch64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .loongarch64, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .mips64el, .os_tag = .linux, .abi = .muslabi64 },
    .{ .cpu_arch = .mipsel, .os_tag = .linux, .abi = .musleabihf },
    .{ .cpu_arch = .x86_64, .os_tag = .macos },
    .{ .cpu_arch = .aarch64, .os_tag = .macos },
    .{ .cpu_arch = .x86_64, .os_tag = .windows },
    .{ .cpu_arch = .aarch64, .os_tag = .windows },
    .{ .cpu_arch = .x86, .os_tag = .windows },
    .{ .cpu_arch = .x86_64, .os_tag = .freebsd },
    .{ .cpu_arch = .aarch64, .os_tag = .freebsd },
    .{ .cpu_arch = .x86_64, .os_tag = .netbsd },
    .{ .cpu_arch = .x86_64, .os_tag = .openbsd },
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const version = b.option([]const u8, "version-string", "Override version string") orelse "0.0.0";

    const build_options = b.addOptions();
    build_options.addOption([]const u8, "version", version);

    const whats = b.addModule("whats", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    addDependencies(b, whats, target, optimize);

    const exe = b.addExecutable(.{
        .name = "whats",
        .root_module = cliModule(b, whats, build_options, target, optimize),
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const lib_tests = b.addTest(.{ .root_module = whats });
    const cli_tests = b.addTest(.{
        .root_module = cliModule(b, whats, build_options, target, optimize),
    });

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&b.addRunArtifact(lib_tests).step);
    test_step.dependOn(&b.addRunArtifact(cli_tests).step);

    const release_step = b.step("release", "Build ReleaseSafe binaries for every release target");
    for (release_targets) |query| {
        const triple = query.zigTriple(b.allocator) catch @panic("OOM");
        const resolved = b.resolveTargetQuery(query);

        const library = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = resolved,
            .optimize = .ReleaseSafe,
        });
        addDependencies(b, library, resolved, .ReleaseSafe);

        const release_exe = b.addExecutable(.{
            .name = "whats",
            .root_module = cliModule(b, library, build_options, resolved, .ReleaseSafe),
        });

        const install = b.addInstallArtifact(release_exe, .{
            .dest_dir = .{ .override = .{ .custom = b.fmt("release/{s}", .{triple}) } },
            .pdb_dir = .disabled,
            .implib_dir = .disabled,
        });
        release_step.dependOn(&install.step);
    }
}

fn addDependencies(
    b: *std.Build,
    module: *std.Build.Module,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) void {
    module.addImport("bfstree", b.dependency("bfstree_zig", .{
        .target = target,
        .optimize = optimize,
    }).module("bfstree"));
    module.addImport("xml", b.dependency("xml", .{
        .target = target,
        .optimize = optimize,
    }).module("xml"));
}

fn cliModule(
    b: *std.Build,
    whats: *std.Build.Module,
    build_options: *std.Build.Step.Options,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Module {
    const module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    module.addImport("whats", whats);
    module.addOptions("build_options", build_options);
    return module;
}
