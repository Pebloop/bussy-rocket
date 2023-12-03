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
    camera_elevation: i32 = 0,
    elevation_speed: f32 = 0.01,

    pub fn init(alloc: Allocator) !*Self {
        var self = try alloc.create(Self);
        self.allocator = alloc;
        self.busX = 0;
        self.busY = 0;
        self.camera_elevation = 0;
        self.elevation_speed = 1;
        return self;
    }

    pub fn state(self: *Self) game_data.GameState {
        return game_data.GameState.init(self);
    }

    pub fn update(self: *Self) ?game_data.Trans {
        self.camera_elevation += @intFromFloat(self.elevation_speed);
        self.elevation_speed += 0.01;
        return null;
    }

    pub fn draw(self: *Self, renderer: *SDL.Renderer) void {
        // draw score
        var height_text = [4:0]u8{ ' ', ' ', ' ', ' ' };
        _ = std.fmt.bufPrint(&height_text, "{}", .{self.camera_elevation}) catch |err| {
            std.log.err("Could not format height: {}", .{err});
            @panic("Could not format height");
        };
        assets.assets.fonts.font.draw(24, 100, 30, 0, 0, &height_text, renderer);

        assets.assets.images.bus.draw(renderer, self.busX, self.busY + self.camera_elevation);
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
