const game_data = @import("../game_data.zig");
const SDL = @import("sdl2");
const std = @import("std");
const assets = @import("../asset_manager/asset_list.zig");
const Image = @import("../asset_manager/image.zig").Image;
const Allocator = std.mem.Allocator;

pub const GameplayState = struct {
    const Self = @This();
    allocator: Allocator,
    busX: i32 = 0,
    busY: i32 = 0,

    pub fn init(alloc: Allocator) !*Self {
        var self = try alloc.create(Self);
        self.allocator = alloc;
        self.busX = 0;
        self.busY = 0;
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
        renderer.setColorRGB(0x00, 0x8E, 0x9B) catch |err| {
            std.log.err("Could not set color: {}", .{err});
            @panic("Could not set color");
        };

        assets.assets.images.bus.draw(renderer, self.busX, self.busY);
    }

    pub fn onEvent(self: *Self, event: SDL.Event) ?game_data.Trans {
        switch (event) {
            .key_down => |key| {
                switch (key.keycode) {
                    .left => {
                        self.busX -= 10;
                        return null;
                    },
                    .right => {
                        self.busX += 10;
                        return null;
                    },
                    .up => {
                        self.busY -= 10;
                        return null;
                    },
                    .down => {
                        self.busY += 10;
                        return null;
                    },
                    else => return null,
                }
            },
            else => return null,
        }
        return null;
    }

    pub fn deinit(self: *Self) void {
        self.allocator.destroy(self);
    }
};
