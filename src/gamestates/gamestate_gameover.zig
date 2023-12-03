const game_data = @import("../game_data.zig");
const SDL = @import("sdl2");
const std = @import("std");
const Allocator = std.mem.Allocator;
const assets = @import("../asset_manager/asset_list.zig");

pub const GameOverState = struct {
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

    pub fn update(self: *Self, delta: f64) ?game_data.Trans {
        _ = delta;
        _ = self;
        return null;
    }

    pub fn draw(self: *Self, renderer: *SDL.Renderer) void {
        _ = self;
        assets.assets.images.bus_broken.draw(renderer, 150, 300);
        assets.assets.fonts.font.draw(28, 400, 140, 310, 100, "GameOver", renderer);
    }

    pub fn onEvent(self: *Self, event: SDL.Event) ?game_data.Trans {
        _ = event;
        _ = self;
        return null;
    }

    pub fn deinit(self: *Self) void {
        self.allocator.destroy(self);
    }
};
