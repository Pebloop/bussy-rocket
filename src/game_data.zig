const SDL = @import("sdl2");

pub const Trans = union(enum) {
    to: GameState,
    push: GameState,
    pop,
    quit: u32,
};

pub const GameState = struct {
    const Self = @This();

    ptr: *anyopaque,
    updateFn: *const fn (*anyopaque) ?Trans,
    drawFn: *const fn (*anyopaque, renderer: *SDL.Renderer) void,
    onEventFn: *const fn (*anyopaque, SDL.Event) ?Trans,
    deinitFn: *const fn (*anyopaque) void,

    pub fn init(ptr: anytype) Self {
        const Ptr = @TypeOf(ptr);
        const ptr_info = @typeInfo(Ptr);

        if (ptr_info != .Pointer) @compileError("ptr must be a pointer");
        if (ptr_info.Pointer.size != .One) @compileError("ptr must be a single item pointer");

        const gen = struct {
            pub fn updateImpl(pointer: *anyopaque) ?Trans {
                const self = @as(Ptr, @ptrCast(@alignCast(pointer)));

                return @call(
                    .always_inline,
                    ptr_info.Pointer.child.update,
                    .{self},
                );
            }

            pub fn drawImpl(pointer: *anyopaque, renderer: *SDL.Renderer) void {
                const self = @as(Ptr, @ptrCast(@alignCast(pointer)));

                return @call(
                    .always_inline,
                    ptr_info.Pointer.child.draw,
                    .{ self, renderer },
                );
            }

            pub fn onEventImpl(pointer: *anyopaque, event: SDL.Event) ?Trans {
                const self = @as(Ptr, @ptrCast(@alignCast(pointer)));

                return @call(
                    .always_inline,
                    ptr_info.Pointer.child.onEvent,
                    .{ self, event },
                );
            }

            pub fn deinitImpl(pointer: *anyopaque) void {
                const self = @as(Ptr, @ptrCast(@alignCast(pointer)));

                return @call(
                    .always_inline,
                    ptr_info.Pointer.child.deinit,
                    .{self},
                );
            }
        };

        return .{
            .ptr = ptr,
            .updateFn = gen.updateImpl,
            .drawFn = gen.drawImpl,
            .onEventFn = gen.onEventImpl,
            .deinitFn = gen.deinitImpl,
        };
    }

    pub inline fn update(self: Self) ?Trans {
        return self.updateFn(self.ptr);
    }

    pub inline fn draw(self: Self, renderer: *SDL.Renderer) void {
        return self.drawFn(self.ptr, renderer);
    }

    pub inline fn onEvent(self: Self, event: SDL.Event) ?Trans {
        return self.onEventFn(self.ptr, event);
    }

    pub inline fn deinit(self: Self) void {
        return self.deinitFn(self.ptr);
    }
};

pub const GameData = struct {
    state: GameState,
    renderer: *SDL.Renderer,
};
