const game_data = @import("../game_data.zig");
const SDL = @import("sdl2");
const std = @import("std");
const assets = @import("../asset_manager/asset_list.zig");
const Image = @import("../asset_manager/image.zig").Image;
const Sky = @import("../objects/sky.zig");
const physics = @import("../managers/physics.zig");
const root = @import("root");

const Allocator = std.mem.Allocator;

const physics_to_pixels_ratio = 100.0; // 100 px = 1 physics engine unit
const camera_follows_bus = true;

const Bus = struct {
    const Self = @This();

    rigid_body: physics.Body,
    left_booster: bool = false,
    right_booster: bool = false,

    pub fn init(allocator: Allocator) Self {
        var self = Self{
            .rigid_body = physics.Body.initRigid(allocator, 1, 5),
        };

        self.rigid_body.shapes.addBox(
            (200.0 / physics_to_pixels_ratio),
            (100.0 / physics_to_pixels_ratio),
            0,
        ).setFriction(1);

        self.rigid_body.setPosition(0, 5);

        return self;
    }

    pub fn deinit(self: Self) void {
        self.rigid_body.deinit();
    }

    pub fn getHeight(self: *Self) f32 {
        return @floatCast(self.rigid_body.getPosition().y);
    }

    pub fn update(self: *Self, delta: f64) void {
        _ = delta;

        if (self.left_booster) {
            self.rigid_body.applyForceAt(0, 10, -1.5, 0);
        }

        if (self.right_booster) {
            self.rigid_body.applyForceAt(0, 10, 1.5, 0);
        }
    }

    pub fn draw(self: *Self, renderer: *SDL.Renderer, camx: f32, camy: f32) void {
        const pos = self.rigid_body.getPosition();
        const angle = self.rigid_body.getAngle();

        assets.assets.images.bus.drawExt(
            renderer,
            @intFromFloat(root.width / 2 - camx + pos.x * physics_to_pixels_ratio - 100),
            @intFromFloat(root.height - camy - pos.y * physics_to_pixels_ratio - 50),
            angle,
        );
    }
};

const Ground = struct {
    const Self = @This();

    staticBody: physics.Body,

    pub fn init(allocator: Allocator) Self {
        var self = Self{
            .staticBody = physics.Body.initStatic(allocator),
        };

        self.staticBody.shapes.addSegment(
            -100,
            100.0 / physics_to_pixels_ratio,
            100,
            100.0 / physics_to_pixels_ratio,
            0,
        ).setFriction(1);

        return self;
    }

    pub fn deinit(self: *Self) void {
        self.staticBody.deinit();
    }
};

pub const GameplayState = struct {
    const Self = @This();
    allocator: Allocator,
    ground: Ground,
    bus: Bus,
    camera_elevation: f32 = 0,
    elevation_speed: f32 = 0.01,

    pub fn init(alloc: Allocator) !*Self {
        const self = try alloc.create(Self);

        physics.setGravity(10);

        self.allocator = alloc;
        self.ground = Ground.init(alloc);
        self.bus = Bus.init(alloc);
        self.camera_elevation = 0;
        self.elevation_speed = 0;

        return self;
    }

    pub fn deinit(self: *Self) void {
        self.allocator.destroy(self);
        self.bus.deinit();
        self.ground.deinit();
    }

    pub fn state(self: *Self) game_data.GameState {
        return game_data.GameState.init(self);
    }

    pub fn update(self: *Self, delta: f64) ?game_data.Trans {
        if (camera_follows_bus) {
            self.camera_elevation = @max(0, self.bus.getHeight() * physics_to_pixels_ratio - root.height / 2);
        } else {
            self.camera_elevation += self.elevation_speed * @as(f32, @floatCast(delta));
            self.elevation_speed += 0.01;
        }

        self.bus.update(delta);
        physics.update(delta);
        return null;
    }

    pub fn draw(self: *Self, renderer: *SDL.Renderer) void {
        // draw score
        var height_text = [10:0]u8{ ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ' };
        _ = std.fmt.bufPrint(&height_text, "{}", .{@as(i64, @intFromFloat(self.camera_elevation))}) catch |err| {
            std.log.err("Could not format height: {}", .{err});
            @panic("Could not format height");
        };

        Sky.drawSky(renderer, self.camera_elevation) catch |err| {
            std.log.err("Could not draw sky: {}", .{err});
            @panic("Could not draw sky");
        };
        assets.assets.fonts.font.draw(24, 100, 30, 0, 0, &height_text, renderer);

        self.bus.draw(renderer, 0, -self.camera_elevation);
    }

    pub fn onEvent(self: *Self, event: SDL.Event) ?game_data.Trans {
        switch (event) {
            .key_down => |key| {
                switch (key.keycode) {
                    .left => {
                        self.bus.left_booster = true;
                        return null;
                    },
                    .right => {
                        self.bus.right_booster = true;
                        return null;
                    },
                    else => return null,
                }
            },
            .key_up => |key| {
                switch (key.keycode) {
                    .left => {
                        self.bus.left_booster = false;
                        return null;
                    },
                    .right => {
                        self.bus.right_booster = false;
                        return null;
                    },
                    else => return null,
                }
            },
            else => return null,
        }
        return null;
    }
};
