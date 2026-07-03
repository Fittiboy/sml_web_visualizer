const std = @import("std");
const sokol = @import("sokol");
const cimgui = @import("cimgui");

const Build = std.Build;
const Dependency = Build.Dependency;

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const opt_docking = b.option(bool, "docking", "Build with docking support") orelse true;
    const cimgui_conf = cimgui.getConfig(opt_docking);

    const dep_sokol = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
        .with_sokol_imgui = true,
        .with_tracing = true,
    });
    const dep_cimgui = b.dependency("cimgui", .{
        .target = target,
        .optimize = optimize,
    });

    dep_sokol.artifact("sokol_clib").root_module.addIncludePath(dep_cimgui.path(cimgui_conf.include_dir));

    const mod_main = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    mod_main.addImport("sokol", dep_sokol.module("sokol"));
    mod_main.addImport(cimgui_conf.module_name, dep_cimgui.module(cimgui_conf.module_name));

    if (target.result.cpu.arch.isWasm()) {
        try buildWasm(b, .{
            .mod_main = mod_main,
            .dep_sokol = dep_sokol,
            .dep_cimgui = dep_cimgui,
            .cimgui_clib_name = cimgui_conf.clib_name,
        });
    } else buildNative(b, mod_main);
}

fn buildNative(b: *Build, mod_main: *Build.Module) void {
    const exe = b.addExecutable(.{
        .name = "sml_native_visualizer",
        .root_module = mod_main,
        .use_llvm = true,
        .use_lld = true,
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the executable");
    const run = b.addRunArtifact(exe);
    if (b.args) |args| {
        run.addArgs(args);
    }
    run_step.dependOn(&run.step);
}

const BuildWasmOptions = struct {
    mod_main: *Build.Module,
    dep_sokol: *Dependency,
    dep_cimgui: *Dependency,
    cimgui_clib_name: []const u8,
};

fn buildWasm(b: *Build, opts: BuildWasmOptions) !void {
    const visualizer = b.addLibrary(.{
        .name = "sml_web_visualizer",
        .root_module = opts.mod_main,
    });

    const dep_emsdk = opts.dep_sokol.builder.dependency("emsdk", .{});

    const emsdk_incl_path = dep_emsdk.path("upstream/emscripten/cache/sysroot/include");
    opts.dep_cimgui.artifact(opts.cimgui_clib_name).root_module.addSystemIncludePath(emsdk_incl_path);

    opts.dep_cimgui.artifact(opts.cimgui_clib_name).step.dependOn(&opts.dep_sokol.artifact("sokol_clib").step);

    const link_step = try sokol.emLinkStep(b, .{
        .lib_main = visualizer,
        .target = opts.mod_main.resolved_target.?,
        .optimize = opts.mod_main.optimize.?,
        .emsdk = dep_emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html"),
    });

    b.getInstallStep().dependOn(&link_step.step);

    const run_step = b.step("run", "Run the web version");
    const run = sokol.emRunStep(b, .{ .name = "sml_web_visualizer", .emsdk = dep_emsdk });
    run.step.dependOn(&link_step.step);
    run_step.dependOn(&run.step);
}
