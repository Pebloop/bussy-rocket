const std = @import("std");
const SDL = @import("sdl2");
const game_data = @import("game_data.zig");
const physics = @import("managers/physics.zig");

const gamestate_menu = @import("gamestates/gamestate_menu.zig");
const assets_manager = @import("./asset_manager/asset_list.zig");

pub const width = 1080;
pub const height = 720;

pub fn main() !void {
    physics.init();

    try SDL.init(.{
        .video = true,
        .events = true,
        .audio = true,
    });
    defer SDL.quit();
    try SDL.image.init(.{ .png = true });
    try SDL.ttf.init();
    defer SDL.image.quit();
    defer SDL.ttf.quit();

    var window = try SDL.createWindow(
        "Bussy Rocket",
        .{ .centered = {} },
        .{ .centered = {} },
        width,
        height,
        .{ .vis = .shown },
    );
    defer window.destroy();

    var renderer = try SDL.createRenderer(window, null, .{ .accelerated = true });
    defer renderer.destroy();

    assets_manager.assets.loadAssets(&renderer);

    var gamestate_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    var menu_state: *gamestate_menu.MenuState = try gamestate_menu.MenuState.init(gamestate_allocator.allocator());
    var gamedata = game_data.GameData{
        .state = menu_state.state(),
        .renderer = &renderer,
    };

    var time_miliseconds = SDL.getTicks64();
    var time: f64 = @floatFromInt(time_miliseconds);
    mainLoop: while (true) {
        const ticks_miliseconds = SDL.getTicks64();
        const ticks: f64 = @floatFromInt(ticks_miliseconds);
        const delta = (ticks - time) / 1000.0;
        time = ticks;

        var egg: ?game_data.Trans = null;

        while (SDL.pollEvent()) |ev| {
            switch (ev) {
                .quit => break :mainLoop,
                else => {},
            }
            egg = gamedata.state.onEvent(ev);
        }

        if (egg) |trans| switch (trans) {
            game_data.Trans.to => |new_state| {
                const old_state = gamedata.state;
                gamedata.state = new_state;
                old_state.deinit();
            },
            else => {},
        };

        try renderer.setColorRGB(0x00, 0x00, 0x00);
        try renderer.clear();

        egg = gamedata.state.update(delta);

        gamedata.state.draw(&renderer);

        renderer.present();

        if (egg) |trans| switch (trans) {
            game_data.Trans.to => |new_state| {
                defer gamedata.state.deinit();
                gamedata.state = new_state;
            },
            else => {},
        };

        SDL.delay(10);
    }
}
