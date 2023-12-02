const game_data = @import("../game_data.zig");
const SDL = @import("sdl2");
const std = @import("std");
const gamestate_game = @import("./gamestate_game.zig");

const bus_asset = @embedFile("../assets/images/bus.png");
var bus_texture: ?SDL.Texture = null;
var rotation: f64 = 0;

const text_asset = @embedFile("../assets/fonts/Roboto-Black.ttf");
var title_font: ?SDL.ttf.Font = null;
var title_surface: ?SDL.Surface = null;
var title_texture: ?SDL.Texture = null;

var text_font: ?SDL.ttf.Font = null;
var text_surface: ?SDL.Surface = null;
var text_texture: ?SDL.Texture = null;

var wav: ?SDL.Wav = null;
var done = false;
var audio_len: usize = 0;
var audio_pos: ?[]u8 = null;
var audio: ?SDL.OpenAudioDeviceResult = null;

fn my_callback(userdata: ?*anyopaque, stream: [*c]u8, len: c_int) callconv(.C) void {
    var wav_len: usize = @intCast(len);
    _ = userdata;

    if (audio_len == 0) {
        return;
    }

    if (len > audio_len) {
        wav_len = audio_len;
    }

    std.log.debug("{} {} {}", .{ len, audio_len, wav_len });

    @memset(stream[0..wav_len], 0);
    SDL.mixAudioFormat(stream[0..wav_len], audio_pos.?[0..wav_len], SDL.AudioFormat.s16_lsb, SDL.mix_maxvolume);

    audio_pos = audio_pos.?[wav_len..];
    audio_len -= wav_len;

    std.log.info("audio pos : {s}", .{"test"});
}

pub const MenuState = struct {
    const Self = @This();

    pub fn init() Self {
        return Self{};
    }

    pub fn state(self: *Self) game_data.GameState {
        return game_data.GameState.init(self);
    }

    pub fn update(self: *Self) ?game_data.Trans {
        _ = self;
        rotation += 1;
        return null;
    }

    pub fn draw(self: *Self, renderer: *SDL.Renderer) void {
        _ = self;

        if (bus_texture == null) {
            bus_texture = SDL.image.loadTextureMem(
                renderer.*,
                bus_asset[0..],
                SDL.image.ImgFormat.png,
            ) catch |err| {
                std.log.err("Failed to load bus texture: {}\n", .{err});
                return;
            };
        }

        if (title_font == null) {
            title_font = SDL.ttf.openFontMem(text_asset, true, 24) catch |err| {
                std.log.err("Failed to load font: {}\n", .{err});
                return;
            };

            title_surface = SDL.ttf.Font.renderTextSolid(title_font.?, "Bussy Rocket", SDL.Color{ .r = 255, .g = 255, .b = 255, .a = 0 }) catch |err| {
                std.log.err("Failed to load text: {}\n", .{err});
                return;
            };

            title_texture = SDL.createTextureFromSurface(renderer.*, title_surface.?) catch |err| {
                std.log.err("Failed to create texture from surface: {}\n", .{err});
                return;
            };
        }

        if (text_font == null) {
            text_font = SDL.ttf.openFontMem(text_asset, true, 18) catch |err| {
                std.log.err("Failed to load font: {}\n", .{err});
                return;
            };

            text_surface = SDL.ttf.Font.renderTextSolid(text_font.?, "Press any key to insert coin", SDL.Color{ .r = 255, .g = 255, .b = 255, .a = 0 }) catch |err| {
                std.log.err("Failed to load text: {}\n", .{err});
                return;
            };

            text_texture = SDL.createTextureFromSurface(renderer.*, text_surface.?) catch |err| {
                std.log.err("Failed to create texture from surface: {}\n", .{err});
                return;
            };
        }

        if (done == false) {
            wav = SDL.loadWav("src/gamestates/menu_music.wav") catch |err| {
                std.log.err("Failed to load audio: {}\n", .{err});
                return;
            };

            audio_pos = wav.?.buffer;
            audio_len = wav.?.buffer.len;
            std.log.debug("test {}", .{wav.?.format.buffer_size_in_bytes});

            audio = SDL.openAudioDevice(SDL.OpenAudioDeviceOptions{
                .desired_spec = .{
                    .callback = my_callback,
                    .userdata = null,
                    .sample_rate = wav.?.format.sample_rate,
                    .buffer_size_in_frames = wav.?.format.buffer_size_in_frames,
                    .channel_count = wav.?.format.channel_count,
                },
            }) catch |err| {
                std.log.err("Failed to open audio device: {}\n", .{err});
                return;
            };

            done = true;
        }
        if (audio) |true_audio| {
            true_audio.device.pause(false);
        }

        renderer.copyEx(
            bus_texture.?,
            SDL.Rectangle{
                .x = 540 - 100,
                .y = 340,
                .width = 200,
                .height = 100,
            },
            null,
            rotation,
            null,
            SDL.RendererFlip.none,
        ) catch |err| {
            std.log.err("Failed to copy bus texture: {}\n", .{err});
            return;
        };

        renderer.*.copy(
            title_texture.?,
            SDL.Rectangle{
                .x = 130,
                .y = 100,
                .width = 800,
                .height = 100,
            },
            null,
        ) catch |err| {
            std.log.err("Failed to copy text texture: {}\n", .{err});
            return;
        };

        renderer.*.copy(
            text_texture.?,
            SDL.Rectangle{
                .x = 300,
                .y = 580,
                .width = 440,
                .height = 40,
            },
            null,
        ) catch |err| {
            std.log.err("Failed to copy title texture: {}\n", .{err});
            return;
        };
    }

    pub fn onEvent(self: *Self, event: SDL.Event) ?game_data.Trans {
        _ = self;

        var next_state = gamestate_game.GameplayState.init();

        return switch (event) {
            .key_down => game_data.Trans{
                .to = next_state.state(),
            },
            else => null,
        };
    }
};
