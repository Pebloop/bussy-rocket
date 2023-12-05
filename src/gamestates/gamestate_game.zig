const game_data = @import("../game_data.zig");
const SDL = @import("sdl2");
const std = @import("std");
const assets = @import("../asset_manager/asset_list.zig");
const Image = @import("../asset_manager/image.zig").Image;
const Sky = @import("../objects/sky.zig");
const physics = @import("../managers/physics.zig");
const root = @import("root");

const Allocator = std.mem.Allocator;

const physics_to_pixels_ratio = 10.0; // 100 px = 1 physics engine unit
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

        _ = self.rigid_body.shapes.addBox2(
            0,
            0.0 / physics_to_pixels_ratio,
            (50.0 / physics_to_pixels_ratio),
            (20.0 / physics_to_pixels_ratio),
            // (56.0 / physics_to_pixels_ratio),
            // (20.0 / physics_to_pixels_ratio),
            0,
        ).setFriction(1);

        // _ = self.rigid_body.shapes.addBox2(
        //     -36.0 / physics_to_pixels_ratio,
        //     -24.0 / physics_to_pixels_ratio,
        //     (16.0 / physics_to_pixels_ratio),
        //     (16.0 / physics_to_pixels_ratio),
        //     0,
        // ).setFriction(0);

        // _ = self.rigid_body.shapes.addBox2(
        //     40.0 / physics_to_pixels_ratio,
        //     -24.0 / physics_to_pixels_ratio,
        //     (16.0 / physics_to_pixels_ratio),
        //     (16.0 / physics_to_pixels_ratio),
        //     0,
        // ).setFriction(0);

        self.rigid_body.setPosition(0, 20);

        return self;
    }

    pub fn deinit(self: Self) void {
        self.rigid_body.deinit();
    }

    pub fn getAltitude(self: *Self) f32 {
        return @floatCast(self.rigid_body.getPosition().y);
    }

    pub fn update(self: *Self, delta: f64) void {
        _ = delta;

        if (self.left_booster) {
            self.rigid_body.applyForceAt(
                0,
                10,
                -40.0 / physics_to_pixels_ratio,
                20.0 / physics_to_pixels_ratio,
            );
        }

        if (self.right_booster) {
            self.rigid_body.applyForceAt(
                0,
                10,
                40.0 / physics_to_pixels_ratio,
                20.0 / physics_to_pixels_ratio,
            );
        }
    }

    pub fn draw(self: *Self, renderer: *SDL.Renderer, camx: f32, camy: f32) void {
        const pos = self.rigid_body.getPosition();
        const angle = self.rigid_body.getAngle();

        const w: f32 = @floatFromInt(assets.assets.images.bus.width);
        const h: f32 = @floatFromInt(assets.assets.images.bus.height);

        assets.assets.images.bus.drawExt(
            renderer,
            @intFromFloat(root.width / 2 - camx + pos.x * physics_to_pixels_ratio - w / 2.0),
            @intFromFloat(root.height - camy - pos.y * physics_to_pixels_ratio - h / 2.0),
            angle,
        );
    }
};

const Ground = struct {
    const Self = @This();

    static_body: physics.Body,

    pub fn init(allocator: Allocator) Self {
        var self = Self{
            .static_body = physics.Body.initStatic(allocator),
        };

        _ = self.static_body.shapes.addSegment(
            -100,
            100.0 / physics_to_pixels_ratio,
            100,
            100.0 / physics_to_pixels_ratio,
            0,
        ).setFriction(1);

        _ = self.static_body.shapes.addSegment(-50, 0, -50, 10000, 0).setFriction(1);
        _ = self.static_body.shapes.addSegment(50, 0, 50, 10000, 0).setFriction(1);

        return self;
    }

    pub fn deinit(self: Self) void {
        self.static_body.deinit();
    }
};

pub const Choco = struct {
    const Self = @This();

    static_body: physics.Body,

    pub fn init(allocator: Allocator, x: f32, y: f32) Self {
        var self = Self{
            .static_body = physics.Body.initStatic(allocator),
        };

        _ = self.static_body.shapes.addBox(
            48.0 / physics_to_pixels_ratio,
            44.0 / physics_to_pixels_ratio,
            0.0,
        );

        self.static_body.setPosition(x, y);

        return self;
    }

    pub fn deinit(self: Self) void {
        self.static_body.deinit();
    }

    pub fn draw(self: *Self, renderer: *SDL.Renderer, camx: f32, camy: f32) void {
        const pos = self.static_body.getPosition();
        const angle = self.static_body.getAngle();

        const w = @as(f32, @floatFromInt(assets.assets.images.choco.width));
        const h = @as(f32, @floatFromInt(assets.assets.images.choco.height));

        assets.assets.images.choco.drawExt(
            renderer,
            @intFromFloat(root.width / 2 - camx + pos.x * physics_to_pixels_ratio - w / 2),
            @intFromFloat(root.height - camy - pos.y * physics_to_pixels_ratio - h / 2),
            angle,
        );
    }
};

pub const GameplayState = struct {
    const Self = @This();

    allocator: Allocator,
    ground: Ground,
    bus: Bus,
    chocos: std.ArrayList(Choco),
    generated_choco_altitude: f32,
    camera_elevation: f32,
    elevation_speed: f32,
    score: u32,
    rand: std.rand.DefaultPrng,

    pub fn init(alloc: Allocator) !*Self {
        const self = try alloc.create(Self);

        physics.setGravity(10);

        self.allocator = alloc;
        self.ground = Ground.init(alloc);
        self.bus = Bus.init(alloc);
        self.chocos = std.ArrayList(Choco).init(alloc);
        self.generated_choco_altitude = 50;
        self.camera_elevation = 0;
        self.elevation_speed = 0;
        self.score = 0;
        self.rand = std.rand.DefaultPrng.init(@as(u64, @truncate(@as(u128, @bitCast(std.time.nanoTimestamp())))));

        return self;
    }

    pub fn deinit(self: *Self) void {
        self.allocator.destroy(self);
        self.bus.deinit();
        self.ground.deinit();
        for (self.chocos.items) |choco| {
            choco.deinit();
        }
    }

    pub fn state(self: *Self) game_data.GameState {
        return game_data.GameState.init(self);
    }

    pub fn update(self: *Self, delta: f64) ?game_data.Trans {
        const current_alt = self.bus.getAltitude();

        // create chocos
        const min_generated_choco_altitude = current_alt + 100.0;

        if (min_generated_choco_altitude > self.generated_choco_altitude) {
            const delta_alt = min_generated_choco_altitude - self.generated_choco_altitude;
            const choco_count: u64 = @intFromFloat(delta_alt / 20);

            if (choco_count > 0) {
                for (0..choco_count) |i| {
                    const x = self.rand.random().float(f32) * 100 - 50;
                    const y = (@as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(choco_count))) * delta_alt + self.generated_choco_altitude;
                    const choco = Choco.init(self.allocator, x, y);

                    std.log.debug("created choco at ({}, {})", .{ x, y });

                    self.chocos.append(choco) catch @panic("choco fail!");
                }

                self.generated_choco_altitude = min_generated_choco_altitude;
            }
        }

        if (camera_follows_bus) {
            self.camera_elevation = @max(0, current_alt * physics_to_pixels_ratio - root.height / 2);
        } else {
            self.camera_elevation += self.elevation_speed * @as(f32, @floatCast(delta));
            self.elevation_speed += 0.01;
        }
        self.score = @max(self.score, @as(u32, @intFromFloat(current_alt)));

        self.bus.update(delta);
        physics.update(delta);

        {
            var i = self.chocos.items.len;

            while (i != 0) {
                if (self.chocos.items[i - 1].static_body.collides(&self.bus.rigid_body)) {
                    self.chocos.pop().deinit();
                } else {
                    i -= 1;
                }
            }
        }

        return null;
    }

    pub fn draw(self: *Self, renderer: *SDL.Renderer) void {
        // draw score
        var height_text = [10:0]u8{ ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ' };
        _ = std.fmt.bufPrint(&height_text, "{}", .{self.score}) catch |err| {
            std.log.err("Could not format height: {}", .{err});
            @panic("Could not format height");
        };

        Sky.drawSky(renderer, self.camera_elevation) catch |err| {
            std.log.err("Could not draw sky: {}", .{err});
            @panic("Could not draw sky");
        };
        assets.assets.fonts.font.draw(24, 100, 30, 0, 0, &height_text, renderer);

        for (0..self.chocos.items.len) |i| {
            self.chocos.items[i].draw(renderer, 0, -self.camera_elevation);
        }

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
