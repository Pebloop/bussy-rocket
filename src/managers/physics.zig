const std = @import("std");
const c = @cImport({
    @cInclude("chipmunk/chipmunk.h");
});

const Allocator = std.mem.Allocator;

const SIMULATION_STEP: f64 = 1.0 / 60.0;

var space: ?*c.cpSpace = null;
var last_update: f64 = 0;

pub fn init() void {
    space = c.cpSpaceNew();
}

pub fn deinit() void {
    c.cpSpaceFree(space.?);
}

pub fn setGravity(gravity: f32) void {
    c.cpSpaceSetGravity(space.?, c.cpv(0, -gravity));
}

pub fn update(now: f64) void {
    _ = now;
    // const time_since_last_update = now - last_update;
    // const frames_to_simulate = time_since_last_update / SIMULATION_STEP;
    // const whole_frames_to_simulate = frames_to_simulate;
    // const left_over_frames = frames_to_simulate - whole_frames_to_simulate;

    // for (0..@as(i64, @intFromFloat(whole_frames_to_simulate))) |_| {
    c.cpSpaceStep(space.?, SIMULATION_STEP);
    // }

    // last_update = now - left_over_frames * SIMULATION_STEP;
}

const Shape = struct {
    const Self = @This();

    ptr: *c.cpShape,

    pub fn setFriction(self: Self, f: f32) Shape {
        c.cpShapeSetFriction(self.ptr, f);
        return self;
    }
};

const Shapes = struct {
    const Self = @This();
    const ShapeList = std.ArrayList(*c.cpShape);

    body: *c.cpBody,
    shapes: ShapeList,

    pub fn init(allocator: Allocator, body: *c.cpBody) Self {
        var self = Self{
            .body = body,
            .shapes = ShapeList.init(allocator),
        };

        return self;
    }

    pub fn deinit(self: Self) void {
        for (self.shapes.items) |shape| {
            c.cpSpaceRemoveShape(space.?, shape);
            c.cpShapeFree(shape);
        }

        self.shapes.deinit();
    }

    pub fn addSegment(
        self: *Self,
        ax: f32,
        ay: f32,
        bx: f32,
        by: f32,
        radius: f32,
    ) Shape {
        const shape = Shape{
            .ptr = c.cpSegmentShapeNew(
                self.body,
                c.cpv(ax, ay),
                c.cpv(bx, by),
                radius,
            ) orelse @panic("oups"),
        };

        _ = c.cpSpaceAddShape(space.?, shape.ptr);

        return shape;
    }

    pub fn addBox(
        self: *Self,
        width: f32,
        height: f32,
        radius: f32,
    ) Shape {
        const shape = Shape{
            .ptr = c.cpBoxShapeNew(
                self.body,
                width,
                height,
                radius,
            ) orelse @panic("oups"),
        };

        _ = c.cpSpaceAddShape(space.?, shape.ptr);

        return shape;
    }

    pub fn addBox2(
        self: *Self,
        x: f32,
        y: f32,
        width: f32,
        height: f32,
        radius: f32,
    ) Shape {
        const shape = Shape{
            .ptr = c.cpBoxShapeNew2(
                self.body,
                c.cpBBNew(x - width / 2.0, y - height / 2.0, x + width, y + height),
                radius,
            ) orelse @panic("oups"),
        };

        _ = c.cpSpaceAddShape(space.?, shape.ptr);

        return shape;
    }
};

pub const Body = struct {
    const Self = @This();

    ptr: *c.cpBody,
    shapes: Shapes,

    pub fn initRigid(allocator: Allocator, mass: f32, moment: f32) Self {
        const ptr = c.cpBodyNew(mass, moment) orelse @panic("cant");
        const self = Self{
            .ptr = ptr,
            .shapes = Shapes.init(allocator, ptr),
        };

        _ = c.cpSpaceAddBody(space.?, self.ptr);

        return self;
    }

    pub fn initStatic(allocator: Allocator) Self {
        const ptr = c.cpBodyNewStatic() orelse @panic("error");
        const self = Self{
            .ptr = ptr,
            .shapes = Shapes.init(allocator, ptr),
        };

        _ = c.cpSpaceAddBody(space.?, self.ptr);

        return self;
    }

    pub fn deinit(self: Self) void {
        self.shapes.deinit();

        c.cpSpaceRemoveBody(space.?, self.ptr);
        c.cpBodyFree(self.ptr);
    }

    pub fn collides(self: *Self, other: *Self) bool {
        for (self.shapes.shapes.items) |shape| {
            for (other.shapes.shapes.items) |other_shape| {
                const contacts = c.cpShapesCollide(shape, other_shape);

                if (contacts.count != 0) {
                    return true;
                }
            }
        }

        return false;
    }

    pub fn setPosition(self: *Self, x: f32, y: f32) void {
        c.cpBodySetPosition(self.ptr, c.cpv(x, y));
        c.cpSpaceReindexShapesForBody(space, self.ptr);
    }

    pub fn getPosition(self: *Self) c.cpVect {
        return c.cpBodyGetPosition(self.ptr);
    }

    pub fn getAngle(self: *Self) f32 {
        return @floatCast(c.cpBodyGetAngle(self.ptr));
    }

    pub fn applyForce(self: *Self, fx: f32, fy: f32) void {
        self.applyForceAt(fx, fy, 0, 0);
    }

    pub fn applyForceAt(self: *Self, fx: f32, fy: f32, px: f32, py: f32) void {
        c.cpBodyApplyForceAtLocalPoint(self.ptr, c.cpv(fx, fy), c.cpv(px, py));
    }
};
