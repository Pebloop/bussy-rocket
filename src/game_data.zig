const SDL = @import("sdl2");

pub const GameState = struct { run: *const fn (*GameData) *GameData, on_event: *const fn (*GameData, SDL.Event) *GameData };

pub const GameData = struct { state: GameState, renderer: *SDL.Renderer };
