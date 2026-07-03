const build_options = @import("build_options");
const std = @import("std");
const sokol = @import("sokol");
const ig = if (build_options.docking) @import("cimgui_docking") else @import("cimgui");
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const simgui = sokol.imgui;

const state = struct {
    var pass_action: sg.PassAction = .{};
    var show_first_window: bool = true;
    var show_second_window: bool = true;
};

export fn init() void {
    sg.setup(.{
        .environment = sglue.environment(),
    });
    simgui.setup(.{});

    if (build_options.docking) {
        ig.igGetIO().*.ConfigFlags |= ig.ImGuiConfigFlags_DockingEnable;
    }

    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.0, .g = 0.5, .b = 1.0, .a = 1.0 },
    };

    std.debug.print("Sokol backend: {}\n", .{sg.queryBackend()});
}

export fn frame() void {
    simgui.newFrame(.{
        .width = sapp.width(),
        .height = sapp.height(),
        .delta_time = sapp.frameDuration(),
        .dpi_scale = sapp.dpiScale(),
    });

    // Now do ImGui stuff here!!
    ig.igSetNextWindowPos(.{ .x = 10, .y = 30 }, ig.ImGuiCond_Once);
    ig.igSetNextWindowSize(.{ .x = 400, .y = 100 }, ig.ImGuiCond_Once);
    if (ig.igBegin("Hello Dear ImGui!", &state.show_first_window, ig.ImGuiWindowFlags_None)) {
        _ = ig.igColorEdit3("Background", &state.pass_action.colors[0].clear_value.r, ig.ImGuiColorEditFlags_None);
        _ = ig.igText("Dear ImGui Version: %s", ig.IMGUI_VERSION);
    }
    ig.igEnd();

    ig.igSetNextWindowPos(.{ .x = 50, .y = 150 }, ig.ImGuiCond_Once);
    ig.igSetNextWindowSize(.{ .x = 400, .y = 100 }, ig.ImGuiCond_Once);
    if (ig.igBegin("Another Window", &state.show_second_window, ig.ImGuiWindowFlags_None)) {
        _ = ig.igText("Hello there, user!");
    }
    ig.igEnd();

    var show_demo: bool = true;
    ig.igShowDemoWindow(&show_demo);

    sg.beginPass(.{ .action = state.pass_action, .swapchain = sglue.swapchain() });
    simgui.render();
    sg.endPass();
    sg.commit();
}

export fn event(ev: [*c]const sapp.Event) void {
    _ = simgui.handleEvent(ev.*);
}

export fn cleanup() void {
    sg.shutdown();
}

pub fn main() void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = event,

        .width = 960,
        .height = 640,
        .window_title = "SML Web Visualizer",
        .icon = .{ .sokol_default = true },

        .win32 = .{ .console_attach = true },
    });
}
