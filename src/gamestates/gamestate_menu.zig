const game_data = @import("../game_data.zig");
const SDL = @import("sdl2");
const std = @import("std");
const gamestate_game = @import("./gamestate_game.zig");
const Allocator = std.mem.Allocator;

pub const MenuState = struct {
    const Self = @This();
    allocator: Allocator,

    pub fn init(alloc: Allocator) !*Self {
        var self = try alloc.create(Self);
        self.allocator = alloc;
        return self;
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
        renderer.setColorRGB(0x84, 0x5E, 0xC2) catch |err| {
            std.log.err("Could not set color: {}", .{err});
            @panic("Could not set color");
        };
        renderer.drawRect(SDL.Rectangle{
            .x = 0,
            .y = 0,
            .width = 30,
            .height = 30,
        }) catch |err| {
            std.log.err("Could not display rectangle: {}", .{err});
            @panic("Could not display rectangle");
        };
    }

    pub fn onEvent(self: *Self, event: SDL.Event) ?game_data.Trans {
        var next_state = gamestate_game.GameplayState.init(self.allocator) catch @panic("Allocation failed!");

        return switch (event) {
            .key_down => game_data.Trans{
                .to = next_state.state(),
            },
            else => null,
        };
    }

    pub fn deinit(self: *Self) void {
        self.allocator.destroy(self);
    }
};
