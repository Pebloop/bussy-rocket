const std = @import("std");
const SDL = @import("sdl2");
const game_data = @import("game_data.zig");
const cm2d = @cImport({
    @cInclude("chipmunk/chipmunk.h");
});

const gamestate_menu = @import("gamestates/gamestate_menu.zig");
const assets_manager = @import("./asset_manager/asset_list.zig");

// const gamestate_menu = @import("gamestates/gamestate_menu.zig").gamestate_menu;
// const gamestate_game = @import("gamestates/gamestate_game.zig").gamestate_game;

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
    try SDL.ttf.init();
    defer SDL.image.quit();
    defer SDL.ttf.quit();

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

    assets_manager.assets.loadAssets(&renderer);

    var gamestate_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    var menu_state: *gamestate_menu.MenuState = try gamestate_menu.MenuState.init(gamestate_allocator.allocator());
    var gamedata = game_data.GameData{
        .state = menu_state.state(),
        .renderer = &renderer,
    };

    var time_miliseconds = SDL.getTicks64();
    var time: f64 = @floatFromInt(time_miliseconds);
    mainLoop: while (true) {
        const ticks_miliseconds = SDL.getTicks64();
        const ticks: f64 = @floatFromInt(ticks_miliseconds);
        const delta = (ticks - time) / 1000.0;
        time = ticks;

        var egg: ?game_data.Trans = null;

        while (SDL.pollEvent()) |ev| {
            switch (ev) {
                .quit => break :mainLoop,
                else => {},
            }
            egg = gamedata.state.onEvent(ev);
        }

        if (egg) |trans| switch (trans) {
            game_data.Trans.to => |new_state| {
                const old_state = gamedata.state;
                gamedata.state = new_state;
                old_state.deinit();
            },
            else => {},
        };

        try renderer.setColorRGB(0x00, 0x00, 0x00);
        try renderer.clear();

        egg = gamedata.state.update(delta);

        gamedata.state.draw(&renderer);

        renderer.present();

        if (egg) |trans| switch (trans) {
            game_data.Trans.to => |new_state| {
                defer gamedata.state.deinit();
                gamedata.state = new_state;
            },
            else => {},
        };

        SDL.delay(10);
    }
}
