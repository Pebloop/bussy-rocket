const std = @import("std");
const SDL = @import("sdl2"); // Created in build.zig by using exe.addModule("sdl2", sdk.getWrapperModule());
const game_data = @import("game_data.zig");
const gamestate_menu = @import("gamestates/gamestate_menu.zig").gamestate_menu;
const gamestate_game = @import("gamestates/gamestate_game.zig").gamestate_game;

pub fn main() !void {
    try SDL.init(.{
        .video = true,
        .events = true,
        .audio = true,
    });
    defer SDL.quit();

    var window = try SDL.createWindow(
        "SDL2 Wrapper Demo",
        .{ .centered = {} },
        .{ .centered = {} },
        640,
        480,
        .{ .vis = .shown },
    );
    defer window.destroy();

    var renderer = try SDL.createRenderer(window, null, .{ .accelerated = true });
    defer renderer.destroy();

    var gamedata = game_data.GameData{ .state = gamestate_menu, .renderer = &renderer };

    mainLoop: while (true) {
        while (SDL.pollEvent()) |ev| {
            switch (ev) {
                .quit => break :mainLoop,
                else => {},
            }
            _ = gamedata.state.on_event(&gamedata, ev);
        }

        try renderer.setColorRGB(0xF7, 0xA4, 0x1D);
        try renderer.clear();

        _ = gamedata.state.run(&gamedata);

        renderer.present();
    }
}
