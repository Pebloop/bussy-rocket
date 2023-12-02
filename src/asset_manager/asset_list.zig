const Image = @import("./image.zig");
const SDL = @import("sdl2");
const std = @import("std");

const imagesList = struct {
    pub var bus = Image.createImage(@embedFile("../assets/images/bus.png"), 200, 100);
};

const fontList = struct {
    pub var font = @embedFile("../assets/fonts/Roboto-Black.ttf");
};

pub const AssetsList = struct {
    pub const images = imagesList;
    pub const fonts = fontList;

    pub fn loadAssets(assets: *AssetsList, renderer: *SDL.Renderer) void {
        assets.images.bus.load(renderer);
        std.log.info("bus : ", .{assets.images.bus});
    }
};

pub fn createAssetsList() AssetsList {
    return AssetsList{
        .images = imagesList,
        .fonts = fontList,
    };
}
