const SDL = @import("sdl2");
const std = @import("std");

pub fn drawSky(renderer: *SDL.Renderer, camera_elevation: f32) !void {
    if (camera_elevation < 6000.0) {
        try renderer.setColorRGB(0x62, 0xba, 0xcb);
        try renderer.fillRect(SDL.Rectangle{ .x = 0, .y = 0, .width = 1080, .height = 2000 });
    } else {
        const sky_gradient = (camera_elevation - 6000.0) / 20000.0;
        const sky_color: f32 = 1 - std.math.clamp(sky_gradient, 0.0, 1.0);
        const r = @as(u8, @intFromFloat(sky_color * 0x62));
        const g = @as(u8, @intFromFloat(sky_color * 0xba));
        const b = @as(u8, @intFromFloat(sky_color * 0xcb));
        // draw sky
        try renderer.setColorRGB(r, g, b);
        try renderer.fillRect(SDL.Rectangle{ .x = 0, .y = 0, .width = 1080, .height = 2000 });
    }
    try renderer.setColorRGB(0x51, 0xdb, 0x76);
    try renderer.fillRect(SDL.Rectangle{
        .x = 0,
        .y = 720 - 100 + @as(i32, @intFromFloat(camera_elevation)),
        .width = 1080,
        .height = 100,
    });
}
