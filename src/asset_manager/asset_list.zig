const Image = @import("./image.zig");
const SDL = @import("sdl2");
const std = @import("std");

const ImagesList = struct {
    bus: Image.Image = Image.createImage(@embedFile("../assets/images/bus.png"), 200, 100),
};

const FontList = struct {
    font: [:0]const u8 = @embedFile("../assets/fonts/Roboto-Black.ttf"),
};

pub const AssetsList = struct {
    images: ImagesList = ImagesList{},
    fonts: FontList = FontList{},

    pub fn loadAssets(assetsList: *AssetsList, renderer: *SDL.Renderer) void {
        assetsList.images.bus.load(renderer);
    }
};

pub var assets: AssetsList = AssetsList{};
