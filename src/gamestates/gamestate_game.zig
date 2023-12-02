const game_data = @import("../game_data.zig");
const SDL = @import("sdl2");
const std = @import("std");

pub const GameplayState = struct {
    const Self = @This();

    pub fn init() Self {
        return Self{};
    }

    pub fn state(self: *Self) game_data.GameState {
        return game_data.GameState.init(self);
    }

    pub fn update(self: *Self) ?game_data.Trans {
        _ = self;
        return null;
    }

    pub fn draw(self: *Self, renderer: *SDL.Renderer) void {
        _ = self;
        renderer.setColorRGB(0x00, 0x8E, 0x9B) catch |err| {
            std.log.err("Could not set color: {}", .{err});
            @panic("Could not set color");
        };
        renderer.drawRect(SDL.Rectangle{
            .x = 30,
            .y = 30,
            .width = 30,
            .height = 30,
        }) catch |err| {
            std.log.err("Could not display rectangle: {}", .{err});
            @panic("Could not display rectangle");
        };
    }

    pub fn onEvent(self: *Self, event: SDL.Event) ?game_data.Trans {
        _ = event;
        _ = self;

        return null;
    }
};
