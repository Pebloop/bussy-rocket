const SDL = @import("sdl2");

pub fn drawSky(renderer: *SDL.Renderer, camera_elevation: i32) !void {
    // draw sky
    try renderer.setColorRGB(0x51, 0xdb, 0x76);
    try renderer.fillRect(SDL.Rectangle{ .x = 0, .y = 720 - 100 + camera_elevation, .width = 1080, .height = 100 });
    try renderer.setColorRGB(0x51, 0xbd, 0xdb);
    try renderer.fillRect(SDL.Rectangle{ .x = 0, .y = 620 - 2000 + camera_elevation, .width = 1080, .height = 2000 });
}
