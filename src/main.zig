const std = @import("std");
const sokol = @import("sokol");

const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;

const state = struct {
    var pass_action: sg.PassAction = .{};
};

export fn init() void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{
            .r = 0.08,
            .g = 0.09,
            .b = 0.11,
            .a = 1.0,
        },
    };

    std.debug.print("Sokol backend: {}\n", .{sg.queryBackend()});
}

export fn frame() void {
    sg.beginPass(.{
        .action = state.pass_action,
        .swapchain = sglue.swapchain(),
    });

    sg.endPass();
    sg.commit();
}

export fn cleanup() void {
    sg.shutdown();
}

pub fn main() void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,

        .width = 960,
        .height = 640,
        .window_title = "SML Web Visualizer",
        .icon = .{ .sokol_default = true },
        .depth_format = .NONE,

        .logger = .{ .func = slog.func },
        .win32 = .{ .console_attach = true },
    });
}
