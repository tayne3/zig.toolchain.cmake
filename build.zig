const std = @import("std");

const TargetCase = struct {
    zig_target: []const u8,
    os_tag: std.Target.Os.Tag,
    cpu_arch: std.Target.Cpu.Arch,
    exe_suffix: []const u8,
};

const test_cases = [_]TargetCase{
    // Linux x64 (glibc)
    .{ .zig_target = "x86_64-linux-gnu", .os_tag = .linux, .cpu_arch = .x86_64, .exe_suffix = "" },
    // Linux ARM64 (glibc)
    .{ .zig_target = "aarch64-linux-gnu", .os_tag = .linux, .cpu_arch = .aarch64, .exe_suffix = "" },
    // Linux x64 (musl)
    .{ .zig_target = "x86_64-linux-musl", .os_tag = .linux, .cpu_arch = .x86_64, .exe_suffix = "" },
    // Linux ARM64 (musl)
    .{ .zig_target = "aarch64-linux-musl", .os_tag = .linux, .cpu_arch = .aarch64, .exe_suffix = "" },
    // Windows x64
    .{ .zig_target = "x86_64-windows-gnu", .os_tag = .windows, .cpu_arch = .x86_64, .exe_suffix = ".exe" },
    // Windows ARM64
    .{ .zig_target = "aarch64-windows-gnu", .os_tag = .windows, .cpu_arch = .aarch64, .exe_suffix = ".exe" },
    // macOS x64
    .{ .zig_target = "x86_64-macos", .os_tag = .macos, .cpu_arch = .x86_64, .exe_suffix = "" },
    // macOS ARM64
    .{ .zig_target = "aarch64-macos", .os_tag = .macos, .cpu_arch = .aarch64, .exe_suffix = "" },
};

const Fixture = struct {
    name: []const u8,
    dir: []const u8,
    bin_name: []const u8,
    windows_only: bool = false,
};

const fixtures = [_]Fixture{
    .{ .name = "c_demo", .dir = "c_demo", .bin_name = "demo_app" },
    .{ .name = "cpp_demo", .dir = "cpp_demo", .bin_name = "cpp_app" },
    .{ .name = "static_lib", .dir = "static_lib", .bin_name = "static_app" },
    .{ .name = "shared_lib", .dir = "shared_lib", .bin_name = "shared_app" },
    .{ .name = "windows_rc", .dir = "windows_rc", .bin_name = "rc_app", .windows_only = true },
};

const VerifyStep = struct {
    step: std.Build.Step,
    target_case: TargetCase,
    fixture: Fixture,

    pub fn create(b: *std.Build, t: TargetCase, f: Fixture) *VerifyStep {
        const self = b.allocator.create(VerifyStep) catch @panic("OOM");
        self.* = .{
            .step = std.Build.Step.init(.{
                .id = .custom,
                .name = b.fmt("verify-{s}-{s}", .{ f.name, t.zig_target }),
                .owner = b,
                .makeFn = make,
            }),
            .target_case = t,
            .fixture = f,
        };
        return self;
    }

    fn make(step: *std.Build.Step, options: std.Build.Step.MakeOptions) !void {
        _ = options;
        const self: *VerifyStep = @fieldParentPtr("step", step);
        // Skip incompatible tests early. We don't want to fail the build for
        // fixtures that are known to be platform-specific (e.g., Windows RC files).
        if (self.fixture.windows_only and self.target_case.os_tag != .windows) {
            return;
        }
        try run_cmake_and_verify(step.owner, self.target_case, self.fixture);
    }
};

pub fn build(b: *std.Build) void {
    const test_step = b.step("test", "Run all cross-compilation tests");
    for (test_cases) |t| {
        for (fixtures) |f| {
            const verify_task = VerifyStep.create(b, t, f);
            test_step.dependOn(&verify_task.step);
        }
    }
}

fn run_cmake_and_verify(b: *std.Build, t: TargetCase, f: Fixture) !void {
    const allocator = b.allocator;
    const cwd = try std.fs.cwd().realpathAlloc(allocator, ".");
    defer allocator.free(cwd);

    const toolchain_path = try std.fs.path.join(allocator, &.{ cwd, "zig.toolchain.cmake" });
    const build_dir = try std.fs.path.join(allocator, &.{ cwd, "build", "tests", f.name, t.zig_target });
    const source_dir = try std.fs.path.join(allocator, &.{ cwd, "tests", f.dir });

    std.debug.print("\n[TEST] Testing Target: {s} | Fixture: {s}...\n", .{ t.zig_target, f.name });

    // We explicitly specify the toolchain file and Zig target to force CMake
    // to use our cross-compilation logic instead of detecting the host environment.
    const cmake_conf_args = &[_][]const u8{
        "cmake",
        "-B",
        build_dir,
        "-S",
        source_dir,
        "-G",
        "Ninja",
        b.fmt("-DCMAKE_TOOLCHAIN_FILE={s}", .{toolchain_path}),
        b.fmt("-DZIG_TARGET={s}", .{t.zig_target}),
    };

    const cmake_build_args = &[_][]const u8{
        "cmake",
        "--build",
        build_dir,
    };

    try run_command(allocator, cmake_conf_args);
    try run_command(allocator, cmake_build_args);
    const bin_path = try std.fs.path.join(allocator, &.{ build_dir, b.fmt("{s}{s}", .{ f.bin_name, t.exe_suffix }) });
    defer allocator.free(bin_path);

    // Validates that the generated binary actually matches the target architecture.
    // This is crucial because CMake might silently fall back to the host compiler
    // if the toolchain configuration is incorrect.
    try verify_binary_header(bin_path, t.os_tag, t.cpu_arch);
    std.debug.print("[PASS] {s} for {s}\n", .{ f.name, t.zig_target });
}

const ELF_MAGIC = "\x7fELF";
const PE_MAGIC = "MZ";
const PE_SIGNATURE = "PE\x00\x00";
const MACHO_MAGIC_64 = 0xFEEDFACF;
const MACHO_CPU_TYPE_X86_64 = 0x01000007;
const MACHO_CPU_TYPE_ARM64 = 0x0100000C;

fn verify_binary_header(path: []const u8, os_tag: std.Target.Os.Tag, cpu_arch: std.Target.Cpu.Arch) !void {
    const file = std.fs.cwd().openFile(path, .{}) catch |err| {
        std.debug.print("Could not open binary file: {s}\n", .{path});
        return err;
    };
    defer file.close();

    var buffer: [1024]u8 = undefined;
    const bytes_read = try file.read(&buffer);
    if (bytes_read < 64) {
        return error.FileTooSmall;
    }
    switch (os_tag) {
        .linux => {
            if (!std.mem.eql(u8, buffer[0..4], ELF_MAGIC)) {
                return error.InvalidElfMagic;
            }
            const machine = std.mem.readInt(u16, buffer[0x12..][0..2], .little);
            switch (cpu_arch) {
                .x86_64 => if (machine != 0x3E) return error.ArchMismatch,
                .aarch64 => if (machine != 0xB7) return error.ArchMismatch,
                else => {},
            }
        },
        .windows => {
            if (!std.mem.eql(u8, buffer[0..2], PE_MAGIC)) {
                return error.InvalidDosHeader;
            }
            const pe_offset = std.mem.readInt(u32, buffer[0x3C..][0..4], .little);
            if (pe_offset + 6 > bytes_read) {
                return error.HeaderOutOfBounds;
            }
            const pe_sig = buffer[pe_offset .. pe_offset + 4];
            if (!std.mem.eql(u8, pe_sig, PE_SIGNATURE)) {
                return error.InvalidPeSignature;
            }
            const machine_offset = pe_offset + 4;
            const machine = std.mem.readInt(u16, buffer[machine_offset..][0..2], .little);
            switch (cpu_arch) {
                .x86_64 => if (machine != 0x8664) return error.ArchMismatch,
                .aarch64 => if (machine != 0xAA64) return error.ArchMismatch,
                else => {},
            }
        },
        .macos => {
            const magic = std.mem.readInt(u32, buffer[0..][0..4], .little);
            if (magic != MACHO_MAGIC_64) {
                return error.InvalidMachOMagic;
            }
            const cpu_type = std.mem.readInt(u32, buffer[4..][0..4], .little);

            switch (cpu_arch) {
                .x86_64 => if (cpu_type != MACHO_CPU_TYPE_X86_64) return error.ArchMismatch,
                .aarch64 => if (cpu_type != MACHO_CPU_TYPE_ARM64) return error.ArchMismatch,
                else => {},
            }
        },
        else => return error.UnsupportedOsForVerification,
    }
}

fn run_command(allocator: std.mem.Allocator, argv: []const []const u8) !void {
    var child = std.process.Child.init(argv, allocator);
    // Ignore stdout to avoid memory pressure from capturing large outputs.
    // We rely on stderr for error reporting and exit codes for status.
    child.stdout_behavior = .Ignore;
    child.stderr_behavior = .Inherit;

    const term = try child.spawnAndWait();
    switch (term) {
        .Exited => |code| {
            if (code != 0) {
                std.debug.print("Command failed with code {d}\n", .{code});
                return error.CommandFailed;
            }
        },
        else => return error.CommandCrashed,
    }
}
