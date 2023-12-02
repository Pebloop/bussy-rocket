const std = @import("std");
const SDL = @import("sdl2");
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
    try SDL.image.init(.{ .png = true });
    defer SDL.image.quit();

    var window = try SDL.createWindow(
        "Bussy Rocket",
        .{ .centered = {} },
        .{ .centered = {} },
        1080,
        720,
        .{ .vis = .shown },
    );
    defer window.destroy();

    var renderer = try SDL.createRenderer(window, null, .{ .accelerated = true });
    defer renderer.destroy();

    const img = @embedFile("assets/bus.png");
    const texture = try SDL.image.loadTextureMem(
        renderer,
        img[0..],
        SDL.image.ImgFormat.png,
    );
    defer texture.destroy();

    var pressing_left = false;
    var pressing_right = false;
    var pressing_up = false;
    var pressing_down = false;

    var bus_posx: i32 = 0;
    var bus_posy: i32 = 0;

    var gamedata = game_data.GameData{
        .state = gamestate_menu,
        .renderer = &renderer,
    };

    mainLoop: while (true) {
        while (SDL.pollEvent()) |ev| {
            switch (ev) {
                .quit => break :mainLoop,
                .key_down => |key| {
                    switch (key.scancode) {
                        .escape => break :mainLoop,
                        .left => pressing_left = true,
                        .right => pressing_right = true,
                        .up => pressing_up = true,
                        .down => pressing_down = true,
                        else => std.debug.print(
                            "Pressed key: {}\n",
                            .{key.scancode},
                        ),
                    }
                },
                .key_up => |key| {
                    switch (key.scancode) {
                        .left => pressing_left = false,
                        .right => pressing_right = false,
                        .up => pressing_up = false,
                        .down => pressing_down = false,
                        else => std.debug.print(
                            "Released key: {}\n",
                            .{key.scancode},
                        ),
                    }
                },
                else => {},
            }
            _ = gamedata.state.on_event(&gamedata, ev);
        }

        bus_posx += if (pressing_right) 1 else 0;
        bus_posx -= if (pressing_left) 1 else 0;
        bus_posy += if (pressing_down) 1 else 0;
        bus_posy -= if (pressing_up) 1 else 0;

        try renderer.setColorRGB(0xF7, 0xA4, 0x1D);
        try renderer.clear();
        try renderer.copy(texture, .{
            .x = bus_posx,
            .y = bus_posy,
            .height = 100,
            .width = 100,
        }, null);

        _ = gamedata.state.run(&gamedata);

        renderer.present();
        SDL.delay(10);
    }
}
