const Image = @import("./image.zig");
const Font = @import("./font.zig");
const SDL = @import("sdl2");
const std = @import("std");

const ImagesList = struct {
    bus: Image.Image = Image.createImage(@embedFile("../assets/images/bus.png"), 200, 100),
    choco: Image.Image = Image.createImage(@embedFile("../assets/images/choco.png"), 64, 64),
};

const FontList = struct {
    font: Font.Font = Font.createFont(@embedFile("../assets/fonts/Roboto-Black.ttf")),
};

pub const AssetsList = struct {
    images: ImagesList = ImagesList{},
    fonts: FontList = FontList{},

    pub fn loadAssets(assetsList: *AssetsList, renderer: *SDL.Renderer) void {
        assetsList.images.bus.load(renderer);
        assetsList.images.choco.load(renderer);
    }
};

pub var assets: AssetsList = AssetsList{};
