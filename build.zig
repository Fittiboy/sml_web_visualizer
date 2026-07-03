const std = @import("std");
const sokol = @import("sokol");
const cimgui = @import("cimgui");

const Build = std.Build;
const Dependency = Build.Dependency;

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const cimgui_conf = cimgui.getConfig(false);

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

    // if (target.result.cpu.arch.isWasm()) {
    //     try buildWasm(b, .{
    //         .mod_main = mod_main,
    //         .dep_sokol = dep_sokol,
    //     });
    // }

    const exe = b.addExecutable(.{
        .name = "sml_web_visualizer",
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

// const BuildWasmOptions = struct {
//     mod_main: *Build.Module,
//     dep_sokol: *Dependency,
// };
//
// fn buildWasm(b: *Build, opts: BuildWasmOptions) !void {
//     const lib = b.addLibrary(.{
//         .name = "visualization",
//         .root_module = opts.mod_main,
//     });
//
//     const dep_emsdk
// }
