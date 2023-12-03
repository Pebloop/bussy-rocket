const SDL = @import("sdl2");
const std = @import("std");

pub const Font = struct {
    font: [:0]const u8,

    pub fn draw(font: Font, font_size: usize, width: usize, height: usize, x: i32, y: i32, text: [:0]const u8, renderer: *SDL.Renderer) void {
        const fontspec = SDL.ttf.openFontMem(font.font, true, @intCast(font_size)) catch |err| {
            std.log.err("Failed to load font: {}\n", .{err});
            return;
        };

        const surface: SDL.Surface = SDL.ttf.Font.renderTextSolid(fontspec, text, SDL.Color{ .r = 255, .g = 255, .b = 255, .a = 0 }) catch |err| {
            std.log.err("Failed to load text: {}\n", .{err});
            return;
        };

        const texture: SDL.Texture = SDL.createTextureFromSurface(renderer.*, surface) catch |err| {
            std.log.err("Failed to create texture from surface: {}\n", .{err});
            return;
        };

        renderer.copy(texture, SDL.Rectangle{
            .x = x,
            .y = y,
            .width = @intCast(width),
            .height = @intCast(height),
        }, null) catch |err| {
            std.log.err("Failed to copy texture: {}\n", .{err});
            return;
        };

        surface.destroy();
        texture.destroy();
        fontspec.close();
    }
};

pub fn createFont(font: [:0]const u8) Font {
    return Font{ .font = font };
}
