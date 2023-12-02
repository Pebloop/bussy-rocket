const std = @import("std");

fn ArrayStorage(comptime T: type) type {
    if (!@hasDecl(T, "init")) {
        @compileError("Component must have `init` constructor");
    }

    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        values: std.ArrayList(T),

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .allocator = allocator,
                .values = std.ArrayList(T).init(allocator),
            };
        }

        pub fn deinit(self: *Self) void {
            if (@hasDecl(T, "deinit")) {
                while (self.values.popOrNull()) |value| {
                    value.deinit(self.allocator);
                }
            }

            self.values.deinit();
        }

        pub fn add(self: *Self, args: anytype) !void {
            var value = try @call(
                .auto,
                T.init,
                args ++ .{self.allocator},
            );

            try self.values.append(value);
        }
    };
}

pub const Name = struct {
    const Self = @This();

    name: []u8,

    pub fn init(name: []const u8, allocator: std.mem.Allocator) !Self {
        return Self{
            .name = try allocator.dupe(u8, name),
        };
    }

    pub fn deinit(self: *const Self, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
    }
};

pub const Position = struct {
    const Self = @This();

    x: f64,
    y: f64,

    pub fn init(x: f64, y: f64, allocator: std.mem.Allocator) !Self {
        _ = allocator;
        return Self{ .x = x, .y = y };
    }
};

pub const World = struct {
    const Self = @This();

    names: ArrayStorage(Name),
    positions: ArrayStorage(Position),

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .names = ArrayStorage(Name).init(allocator),
            .positions = ArrayStorage(Position).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.names.deinit();
        self.positions.deinit();
    }
};

test "world" {
    var world = World.init(std.testing.allocator);
    defer world.deinit();

    try world.names.add(.{"hello"});
    try world.positions.add(.{ 4, 9 });
}
