const game_data = @import("../game_data.zig");
const SDL = @import("sdl2");
const std = @import("std");
const gamestate_game = @import("./gamestate_game.zig").gamestate_game;

fn gamestate_menu_run(gamedata: *game_data.GameData) *game_data.GameData {
    gamedata.renderer.setColorRGB(0x84, 0x5E, 0xC2) catch |err| {
        std.log.err("Could not set color : {}", .{err});
        return gamedata;
    };
    gamedata.renderer.drawRect(SDL.Rectangle{
        .x = 0,
        .y = 0,
        .width = 30,
        .height = 30,
    }) catch |err| {
        std.log.err("Could not display rectangle : {}", .{err});
        return gamedata;
    };
    return gamedata;
}

fn gamestate_menu_onevent(gamedata: *game_data.GameData, event: SDL.Event) *game_data.GameData {
    switch (event) {
        .key_down => gamedata.state = gamestate_game,
        else => {},
    }
    return gamedata;
}

pub const gamestate_menu = game_data.GameState{
    .run = &gamestate_menu_run,
    .on_event = &gamestate_menu_onevent,
};
