const game_data = @import("../game_data.zig");
const SDL = @import("sdl2");
const std = @import("std");

fn gamestate_game_run(gamedata: *game_data.GameData) *game_data.GameData {
    gamedata.renderer.setColorRGB(0x00, 0x8E, 0x9B) catch |err| {
        std.log.err("Could not set color : {}", .{err});
        return gamedata;
    };
    gamedata.renderer.drawRect(SDL.Rectangle{ .x = 30, .y = 30, .width = 30, .height = 30 }) catch |err| {
        std.log.err("Could not display rectangle : {}", .{err});
        return gamedata;
    };
    return gamedata;
}

fn gamestate_game_onevent(gamedata: *game_data.GameData, event: SDL.Event) *game_data.GameData {
    _ = event;
    return gamedata;
}

pub const gamestate_game = game_data.GameState{ .run = &gamestate_game_run, .on_event = &gamestate_game_onevent };
