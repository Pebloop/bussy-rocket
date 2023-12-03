const SDL = @import("sdl2");
const std = @import("std");

// SDL.mixAudioFormat(stream[0..wav_len], audio_pos.?[0..wav_len], SDL.AudioFormat.s16_lsb, SDL.mix_maxvolume);
fn global_audio_callback(userdata: ?*anyopaque, stream: [*c]u8, len: c_int) callconv(.C) void {
    const engine: *SoundManager = @ptrCast(@alignCast(userdata.?));
    const output_buffer_size: usize = @intCast(len);
    @memset(stream[0..output_buffer_size], 0);

    for (engine.sound_list.items) |sound| {
        if (sound.paused or sound.stopped)
            continue;
        const remaining_bytes_to_copy = sound.current_pos.len;
        const number_of_bytes_to_copy = @min(remaining_bytes_to_copy, output_buffer_size);
        const sdl_volume: c_int = @intFromFloat(sound.volume * SDL.mix_maxvolume);
        const sdl_clamped_volume: c_int = @max(0, @min(SDL.mix_maxvolume, sdl_volume));
        SDL.mixAudioFormat(
            stream[0..number_of_bytes_to_copy],
            sound.current_pos[0..number_of_bytes_to_copy],
            SDL.AudioFormat.s16_lsb,
            sdl_clamped_volume,
        );
        sound.current_pos = sound.current_pos[number_of_bytes_to_copy..];
        if (sound.current_pos.len == 0) {
            if (sound.loop) {
                sound.current_pos = sound.data.buffer;
            } else {
                sound.stopped = true;
            }
        }
    }
}

pub const Wav = struct {
    const Self = @This();
    data: SDL.Wav,
    current_pos: []u8,
    total_len: usize,
    loop: bool,
    paused: bool,
    stopped: bool,
    volume: f32,

    pub fn play(self: *Self) void {
        self.paused = false;
    }
};

pub const SoundManager = struct {
    const Self = @This();
    sound_list: std.ArrayList(*Wav),
    allocator: std.mem.Allocator,
    audio_device: SDL.OpenAudioDeviceResult,

    pub fn init(alloc: std.mem.Allocator) !*Self {
        var self = try alloc.create(Self);
        self.allocator = alloc;
        self.sound_list = std.ArrayList(*Wav).init(alloc);
        self.audio_device = try SDL.openAudioDevice(SDL.OpenAudioDeviceOptions{
            .desired_spec = .{
                .callback = global_audio_callback,
                .userdata = self,
                .sample_rate = 44100,
                .buffer_size_in_frames = 1024,
                .channel_count = 2,
            },
        });
        return self;
    }

    pub fn loadSound(self: *Self, path: [:0]const u8) !*Wav {
        var sound = try self.allocator.create(Wav);
        sound.data = try SDL.loadWav(path);
        sound.current_pos = sound.data.buffer;
        sound.total_len = sound.data.buffer.len;
        sound.loop = false;
        sound.stopped = false;
        sound.paused = true;
        sound.volume = 1;
        try self.sound_list.append(sound);
        return sound;
    }

    pub fn deinit(self: *Self) void {
        self.stop();
        for (self.sound_list) |sound| {
            self.allocator.destroy(sound);
        }
        self.sound_list.deinit();
    }

    pub fn start(self: *Self) void {
        self.audio_device.device.pause(false);
    }

    pub fn stop(self: *Self) void {
        self.audio_device.device.pause(true);
    }
};
