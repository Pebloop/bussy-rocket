const cm2d = @cImport({
    @cInclude("chipmunk/chipmunk.h");
});

pub const position = struct {
    x: f64,
    y: f64,
};

pub const color = enum {
    red,
    yellow,
    pink,
};

pub const renderable = union {
    fill: struct { col: color },
};

pub const sphere = struct {
    radius: u32,
    pos: position,
    friction: f64,
    render: ?renderable,
    shape: *cm2d.cpShape,
};

pub fn sphereNew(
    radius: u32,
    pos: position,
    friction: f64,
    mass: f32,
    render: ?renderable,
) ?sphere {
    const moment = cm2d.cpMomentForCircle(mass, 0, radius, cm2d.cpvzero);
    const shape_opt = cm2d.cpBodyNew(mass, moment);

    if (shape_opt) |shape| {
        return .{
            .radius = radius,
            .pos = pos,
            .friction = friction,
            .render = render,
            .shape = shape,
        };
    }
    return null;
}
