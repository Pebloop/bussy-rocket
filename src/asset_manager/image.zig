const SDL = @import("sdl2");
const std = @import("std");

pub const Image = struct {
    picture: [:0]const u8,
    texture: ?SDL.Texture = null,
    width: c_int,
    height: c_int,

    pub fn load(image: *Image, renderer: *SDL.Renderer) void {
        image.texture = SDL.image.loadTextureMem(
            renderer.*,
            image.picture[0..],
            SDL.image.ImgFormat.png,
        ) catch |err| {
            std.log.err("Failed to load bus texture: {}", .{err});
            return;
        };
    }

    pub fn draw(image: *Image, renderer: *SDL.Renderer, x: c_int, y: c_int) void {
        if (image.texture) |texture| {
            const rect = SDL.Rectangle{
                .x = x,
                .y = y,
                .width = image.width,
                .height = image.height,
            };

            renderer.copy(texture, rect, null) catch |err| {
                std.log.err("Failed to draw bus texture: {}", .{err});
                return;
            };
        }
    }
};

pub fn createImage(picture: [:0]const u8, width: u32, height: u32) Image {
    return Image{
        .picture = picture,
        .texture = null,
        .width = width,
        .height = height,
    };
}
