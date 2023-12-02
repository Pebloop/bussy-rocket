const std = @import("std");
const SDL = @import("sdl2");
const game_data = @import("game_data.zig");
const gamestate_menu = @import("gamestates/gamestate_menu.zig").gamestate_menu;
const gamestate_game = @import("gamestates/gamestate_game.zig").gamestate_game;
const cm2d = @cImport({
    @cInclude("chipmunk/chipmunk.h");
});
const ecs = @import("ecs.zig");

// pub fn main() !void {
//     // cpVect is a 2D vector and cpv() is a shortcut for initializing them.
//     const gravity = cm2d.cpv(0, -100);
//
//     // Create an empty space.
//     const space = cm2d.cpSpaceNew();
//     defer cm2d.cpSpaceFree(space);
//     cm2d.cpSpaceSetGravity(space, gravity);
//
//     // Add a static line segment shape for the ground.
//     // We'll make it slightly tilted so the ball will roll off.
//     // We attach it to a static body to tell Chipmunk it shouldn't be movable.
//     const ground = cm2d.cpSegmentShapeNew(cm2d.cpSpaceGetStaticBody(space), cm2d.cpv(-20, 5), cm2d.cpv(-20, 5), 0);
//     defer cm2d.cpShapeFree(ground);
//     cm2d.cpShapeSetFriction(ground, 1);
//     _ = cm2d.cpSpaceAddShape(space, ground);
//
//     // Now let's make a ball that falls onto the line and rolls off.
//     // First we need to make a cpBody to hold the physical properties of the object.
//     // These include the mass, position, velocity, angle, etc. of the object.
//     // Then we attach collision shapes to the cpBody to give it a size and shape.
//
//     const radius = 5;
//     const mass = 1;
//
//     // The moment of inertia is like mass for rotation
//     // Use the cpMomentFor*() functions to help you approximate it.
//     const moment = cm2d.cpMomentForCircle(mass, 0, radius, cm2d.cpvzero);
//
//     // The cpSpaceAdd*() functions return the thing that you are adding.
//     // It's convenient to create and add an object in one line.
//     const ballBody = cm2d.cpSpaceAddBody(space, cm2d.cpBodyNew(mass, moment));
//     defer cm2d.cpBodyFree(ballBody);
//     cm2d.cpBodySetPosition(ballBody, cm2d.cpv(0, 15));
//
//     // Now we create the collision shape for the ball.
//     // You can create multiple collision shapes that point to the same body.
//     // They will all be attached to the body and move around to follow it.
//     const ballShape = cm2d.cpSpaceAddShape(space, cm2d.cpCircleShapeNew(ballBody, radius, cm2d.cpvzero));
//     defer cm2d.cpShapeFree(ballShape);
//     cm2d.cpShapeSetFriction(ballShape, 0.7);
//
//     const timeStep = 1.0 / 60.0;
//     var time: f32 = 0;
//
//     // Now that it's all set up, we simulate all the objects in the space by
//     // stepping forward through time in small increments called steps.
//     // It is *highly* recommended to use a fixed size time step.
//     while (time < 2) : (time += timeStep) {
//         const pos = cm2d.cpBodyGetPosition(ballBody);
//         const vel = cm2d.cpBodyGetVelocity(ballBody);
//         std.debug.print("Time is {d:.2}. ballBody is at ({d:.2} {d:.2}). It's velocity is ({d:.2} {d:.2})\n", .{ time, pos.x, pos.y, vel.x, vel.y });
//
//         cm2d.cpSpaceStep(space, timeStep);
//     }
// }

pub fn main() !void {
    try SDL.init(.{
        .video = true,
        .events = true,
        .audio = true,
    });
    defer SDL.quit();
    try SDL.image.init(.{ .png = true });
    defer SDL.image.quit();

    var window = try SDL.createWindow(
        "Bussy Rocket",
        .{ .centered = {} },
        .{ .centered = {} },
        1080,
        720,
        .{ .vis = .shown },
    );
    defer window.destroy();

    var renderer = try SDL.createRenderer(window, null, .{ .accelerated = true });
    defer renderer.destroy();

    const img = @embedFile("assets/bus.png");
    const texture = try SDL.image.loadTextureMem(renderer, img[0..], SDL.image.ImgFormat.png);
    defer texture.destroy();

    var pressing_left = false;
    var pressing_right = false;
    var pressing_up = false;
    var pressing_down = false;

    var bus_posx: i32 = 0;
    var bus_posy: i32 = 0;

    var gamedata = game_data.GameData{ .state = gamestate_menu, .renderer = &renderer };

    mainLoop: while (true) {
        while (SDL.pollEvent()) |ev| {
            switch (ev) {
                .quit => break :mainLoop,
                .key_down => |key| {
                    switch (key.scancode) {
                        .escape => break :mainLoop,
                        .left => pressing_left = true,
                        .right => pressing_right = true,
                        .up => pressing_up = true,
                        .down => pressing_down = true,
                        else => std.debug.print("Pressed key: {}\n", .{key.scancode}),
                    }
                },
                .key_up => |key| {
                    switch (key.scancode) {
                        .left => pressing_left = false,
                        .right => pressing_right = false,
                        .up => pressing_up = false,
                        .down => pressing_down = false,
                        else => std.debug.print("Released key: {}\n", .{key.scancode}),
                    }
                },
                else => {},
            }
            _ = gamedata.state.on_event(&gamedata, ev);
        }

        bus_posx += if (pressing_right) 1 else 0;
        bus_posx -= if (pressing_left) 1 else 0;
        bus_posy += if (pressing_down) 1 else 0;
        bus_posy -= if (pressing_up) 1 else 0;

        try renderer.setColorRGB(0xF7, 0xA4, 0x1D);
        try renderer.clear();
        try renderer.copy(texture, .{ .x = bus_posx, .y = bus_posy, .height = 100, .width = 100 }, null);

        _ = gamedata.state.run(&gamedata);

        renderer.present();
        SDL.delay(10);
    }
}
