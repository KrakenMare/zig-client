const std = @import("std");
const main = @import("main.zig");
const builtin = @import("builtin");
const game_data = @import("game_data.zig");

pub fn DynSlice(comptime T: type) type {
    return struct {
        const Self = @This();
        const scale_factor = 2;

        capacity: usize,
        _items: []T,
        _allocator: std.mem.Allocator,

        pub fn init(comptime default_capacity: usize, allocator: std.mem.Allocator) !Self {
            return Self{
                .capacity = 0,
                ._items = try allocator.alloc(T, @max(1, default_capacity)), // have to alloc at least 1, otherwise we can't scale off of len
                ._allocator = allocator,
            };
        }

        pub fn deinit(self: Self) void {
            if (@sizeOf(T) > 0) {
                self._allocator.free(self._items);
            }
        }

        pub inline fn clear(self: *Self) void {
            self.capacity = 0;
        }

        pub inline fn isFull(self: Self) bool {
            return self.capacity >= self._items.len;
        }

        pub inline fn items(self: Self) []T {
            return self._items[0..self.capacity];
        }

        pub inline fn add(self: *Self, item: T) !void {
            if (self.isFull()) {
                self._items = try self._allocator.realloc(self._items, self.capacity * scale_factor);
            }

            self._items[self.capacity] = item;
            self.capacity += 1;
        }

        pub inline fn remove(self: *Self, idx: usize) T {
            self.capacity -= 1;

            const old = self._items[idx];
            self._items[idx] = self._items[self.capacity];
            return old;
        }

        pub inline fn removePtr(self: *Self, idx: usize) *T {
            self.capacity -= 1;

            var old = self._items[idx];
            self._items[idx] = self._items[self.capacity];
            return &old;
        }
    };
}

pub const PacketWriter = struct {
    index: u16 = 0,
    length_index: u16 = 0,
    buffer: [65535]u8 = undefined,

    pub fn writeLength(self: *PacketWriter) void {
        self.length_index = self.index;
        self.index += 2;
    }

    pub fn updateLength(self: *PacketWriter) void {
        const buf = self.buffer[self.length_index .. self.length_index + 2];
        const len = self.index - self.length_index;
        switch (builtin.cpu.arch.endian()) {
            .Little => {
                @memcpy(buf, std.mem.asBytes(&len));
            },
            .Big => {
                var len_buf = std.mem.toBytes(len);
                std.mem.reverse(u8, len_buf[0..2]);
                @memcpy(buf, len_buf[0..2]);
            },
        }
    }

    pub fn writeDirect(self: *PacketWriter, value: []const u8) void {
        const buf = self.buffer[self.index .. self.index + value.len];
        self.index += @intCast(value.len);
        @memcpy(buf, value);
    }

    pub fn write(self: *PacketWriter, value: anytype) void {
        const T = @TypeOf(value);
        const type_info = @typeInfo(T);

        if (type_info == .Pointer and (type_info.Pointer.size == .Slice or type_info.Pointer.size == .Many)) {
            self.writeArray(value);
            return;
        }

        if (type_info == .Array) {
            self.writeArray(value);
            return;
        }

        if (type_info == .Struct) {
            comptime std.debug.assert(type_info.Struct.layout != .Auto);
        }

        const byte_size = (@bitSizeOf(T) + 7) / 8;
        const buf = self.buffer[self.index .. self.index + byte_size];
        self.index += byte_size;

        switch (builtin.cpu.arch.endian()) {
            .Little => {
                @memcpy(buf, std.mem.asBytes(&value));
            },
            .Big => {
                var val_buf = std.mem.toBytes(value);
                std.mem.reverse(u8, val_buf[0..byte_size]);
                @memcpy(buf, val_buf[0..byte_size]);
            },
        }
    }

    inline fn writeArray(self: *PacketWriter, value: anytype) void {
        self.write(@as(u16, @intCast(value.len)));
        for (value) |val|
            self.write(val);
    }
};

pub const PacketReader = struct {
    index: u16 = 0,
    buffer: [65535]u8 = undefined,

    pub fn read(self: *PacketReader, comptime T: type) T {
        const type_info = @typeInfo(T);
        if (type_info == .Pointer and (type_info.Pointer.size == .Slice or type_info.Pointer.size == .Many)) {
            return self.readArray(type_info.Pointer.child);
        }

        if (type_info == .Array) {
            return self.readArray(type_info.Array.child);
        }

        if (type_info == .Struct) {
            comptime std.debug.assert(type_info.Struct.layout != .Auto);
        }

        const byte_size = (@bitSizeOf(T) + 7) / 8;
        var buf = self.buffer[self.index .. self.index + byte_size];
        self.index += byte_size;

        switch (builtin.cpu.arch.endian()) {
            .Little => return std.mem.bytesToValue(T, buf[0..byte_size]),
            .Big => {
                std.mem.reverse(u8, buf[0..byte_size]);
                return std.mem.bytesToValue(T, buf[0..byte_size]);
            },
        }
    }

    inline fn readArray(self: *PacketReader, comptime T: type) []T {
        const len = self.read(u16);
        const buf = main.network_stack_allocator.alloc(T, len) catch unreachable;
        for (0..len) |i| {
            buf[i] = self.read(T);
        }
        return buf;
    }
};

pub const ConditionEnum = enum(u8) {
    unknown = 0,
    dead = 1,
    quiet = 2,
    weak = 3,
    slowed = 4,
    sick = 5,
    dazed = 6,
    stunned = 7,
    blind = 8,
    hallucinating = 9,
    drunk = 10,
    confused = 11,
    stun_immune = 12,
    invisible = 13,
    paralyzed = 14,
    speedy = 15,
    bleeding = 16,
    not_used = 17,
    healing = 18,
    damaging = 19,
    berserk = 20,
    paused = 21,
    stasis = 22,
    stasis_immune = 23,
    invincible = 24,
    invulnerable = 25,
    armored = 26,
    armor_broken = 27,
    hexed = 28,
    ninja_speedy = 29,

    const map = std.ComptimeStringMap(ConditionEnum, .{
        .{ "Unknown", .unknown },
        .{ "Dead", .dead },
        .{ "Quiet", .quiet },
        .{ "Weak", .weak },
        .{ "Slowed", .slowed },
        .{ "Sick", .sick },
        .{ "Dazed", .dazed },
        .{ "Stunned", .stunned },
        .{ "Blind", .blind },
        .{ "Hallucinating", .hallucinating },
        .{ "Drunk", .drunk },
        .{ "Confused", .confused },
        .{ "StunImmune", .stun_immune },
        .{ "Stun Immune", .stun_immune },
        .{ "Invisible", .invisible },
        .{ "Paralyzed", .paralyzed },
        .{ "Speedy", .speedy },
        .{ "Bleeding", .bleeding },
        .{ "Healing", .healing },
        .{ "Damaging", .damaging },
        .{ "Berserk", .berserk },
        .{ "Paused", .paused },
        .{ "Stasis", .stasis },
        .{ "StasisImmune", .stasis_immune },
        .{ "Stasis Immune", .stasis_immune },
        .{ "Invincible", .invincible },
        .{ "Invulnerable", .invulnerable },
        .{ "Armored", .armored },
        .{ "ArmorBroken", .armor_broken },
        .{ "Armor Broken", .armor_broken },
        .{ "Hexed", .hexed },
        .{ "NinjaSpeedy", .ninja_speedy },
        .{ "Ninja Speedy", .ninja_speedy },
    });

    pub fn fromString(str: []const u8) ConditionEnum {
        return map.get(str) orelse .unknown;
    }

    pub fn toString(self: ConditionEnum) []const u8 {
        return switch (self) {
            .dead => "Dead",
            .quiet => "Quiet",
            .weak => "Weak",
            .slowed => "Slowed",
            .sick => "Sick",
            .dazed => "Dazed",
            .stunned => "Stunned",
            .blind => "Blind",
            .hallucinating => "Hallucinating",
            .drunk => "Drunk",
            .confused => "Confused",
            .stun_immune => "Stun Immune",
            .invisible => "Invisible",
            .paralyzed => "Paralyzed",
            .speedy => "Speedy",
            .bleeding => "Bleeding",
            .healing => "Healing",
            .damaging => "Damaging",
            .berserk => "Berserk",
            .paused => "Paused",
            .stasis => "Stasis",
            .stasis_immune => "Stasis Immune",
            .invincible => "Invincible",
            .invulnerable => "Invulnerable",
            .armored => "Armored",
            .armor_broken => "Armor Broken",
            .hexed => "Hexed",
            .ninja_speedy => "Ninja Speedy",
            else => "",
        };
    }
};

pub const Condition = packed struct(u64) {
    dead: bool = false,
    quiet: bool = false,
    weak: bool = false,
    slowed: bool = false,
    sick: bool = false,
    dazed: bool = false,
    stunned: bool = false,
    blind: bool = false,
    hallucinating: bool = false,
    drunk: bool = false,
    confused: bool = false,
    stun_immune: bool = false,
    invisible: bool = false,
    paralyzed: bool = false,
    speedy: bool = false,
    bleeding: bool = false,
    not_used: bool = false,
    healing: bool = false,
    damaging: bool = false,
    berserk: bool = false,
    paused: bool = false,
    stasis: bool = false,
    stasis_immune: bool = false,
    invincible: bool = false,
    invulnerable: bool = false,
    armored: bool = false,
    armor_broken: bool = false,
    hexed: bool = false,
    ninja_speedy: bool = false,
    _padding: u35 = 0,

    pub inline fn fromCondSlice(slice: []game_data.ConditionEffect) Condition {
        var ret = Condition{};
        for (slice) |cond| {
            ret.set(cond.condition, true);
        }
        return ret;
    }

    pub fn set(self: *Condition, cond: ConditionEnum, value: bool) void {
        switch (cond) {
            .quiet => self.quiet = value,
            .weak => self.weak = value,
            .slowed => self.slowed = value,
            .sick => self.sick = value,
            .dazed => self.dazed = value,
            .stunned => self.stunned = value,
            .blind => self.blind = value,
            .hallucinating => self.hallucinating = value,
            .drunk => self.drunk = value,
            .confused => self.confused = value,
            .stun_immune => self.stun_immune = value,
            .invisible => self.invisible = value,
            .paralyzed => self.paralyzed = value,
            .speedy => self.speedy = value,
            .bleeding => self.bleeding = value,
            .healing => self.healing = value,
            .damaging => self.damaging = value,
            .berserk => self.berserk = value,
            .paused => self.paused = value,
            .stasis => self.stasis = value,
            .stasis_immune => self.stasis_immune = value,
            .invincible => self.invincible = value,
            .invulnerable => self.invulnerable = value,
            .armored => self.armored = value,
            .armor_broken => self.armor_broken = value,
            .hexed => self.hexed = value,
            .ninja_speedy => self.ninja_speedy = value,
            else => std.log.err("Invalid enum specified for condition set: {any}", .{@errorReturnTrace() orelse return}),
        }
    }

    pub fn toggle(self: *Condition, cond: ConditionEnum) void {
        switch (cond) {
            .quiet => self.quiet = !self.quiet,
            .weak => self.weak = !self.weak,
            .slowed => self.slowed = !self.slowed,
            .sick => self.sick = !self.sick,
            .dazed => self.dazed = !self.dazed,
            .stunned => self.stunned = !self.stunned,
            .blind => self.blind = !self.blind,
            .hallucinating => self.hallucinating = !self.hallucinating,
            .drunk => self.drunk = !self.drunk,
            .confused => self.confused = !self.confused,
            .stun_immune => self.stun_immune = !self.stun_immune,
            .invisible => self.invisible = !self.invisible,
            .paralyzed => self.paralyzed = !self.paralyzed,
            .speedy => self.speedy = !self.speedy,
            .bleeding => self.bleeding = !self.bleeding,
            .healing => self.healing = !self.healing,
            .damaging => self.damaging = !self.damaging,
            .berserk => self.berserk = !self.berserk,
            .paused => self.paused = !self.paused,
            .stasis => self.stasis = !self.stasis,
            .stasis_immune => self.stasis_immune = !self.stasis_immune,
            .invincible => self.invincible = !self.invincible,
            .invulnerable => self.invulnerable = !self.invulnerable,
            .armored => self.armored = !self.armored,
            .armor_broken => self.armor_broken = !self.armor_broken,
            .hexed => self.hexed = !self.hexed,
            .ninja_speedy => self.ninja_speedy = !self.ninja_speedy,
            else => std.log.err("Invalid enum specified for condition toggle: {any}", .{@errorReturnTrace() orelse return}),
        }
    }
};

pub const Point = struct {
    x: f32,
    y: f32,
};

pub const Rect = struct {
    x: f32,
    y: f32,
    w: f32,
    h: f32,
    w_pad: f32,
    h_pad: f32,
};

pub const Random = struct {
    seed: u32 = 834569746,

    pub fn init(seed: u32) Random {
        return .{ .seed = seed };
    }

    pub fn setSeed(self: *Random, seed: u32) void {
        self.seed = seed;
    }

    pub fn nextIntRange(self: *Random, min: u32, max: u32) u32 {
        if (min == max)
            return min;
        return min + (self.gen() % (max - min));
    }

    fn gen(self: *Random) u32 {
        var lo = 16807 * (self.seed & 0xFFFF);
        const hi = 16807 * (self.seed >> 16);

        lo += (hi & 0x7FFF) << 16;
        lo += hi >> 15;

        if (lo > 0x7FFFFFFF)
            lo -= 0x7FFFFFFF;

        self.seed = lo;
        return lo;
    }
};

pub const VM_COUNTERS_EX = extern struct {
    PeakVirtualSize: std.os.windows.SIZE_T,
    VirtualSize: std.os.windows.SIZE_T,
    PageFaultCount: std.os.windows.ULONG,
    PeakWorkingSetSize: std.os.windows.SIZE_T,
    WorkingSetSize: std.os.windows.SIZE_T,
    QuotaPeakPagedPoolUsage: std.os.windows.SIZE_T,
    QuotaPagedPoolUsage: std.os.windows.SIZE_T,
    QuotaPeakNonPagedPoolUsage: std.os.windows.SIZE_T,
    QuotaNonPagedPoolUsage: std.os.windows.SIZE_T,
    PagefileUsage: std.os.windows.SIZE_T,
    PeakPagefileUsage: std.os.windows.SIZE_T,
    PrivateUsage: std.os.windows.SIZE_T,
};

pub const pi_2 = std.math.pi / 2.0;
pub const pi_4 = std.math.pi / 4.0;

pub var rng = std.rand.DefaultPrng.init(0x99999999);

var last_memory_access: i64 = -1;
var last_memory_value: f32 = -1.0;

pub fn currentMemoryUse() !f32 {
    if (main.current_time - last_memory_access < 5000 * std.time.us_per_ms)
        return last_memory_value;

    var memory_value: f32 = -1.0;
    switch (builtin.os.tag) {
        .windows => {
            var vmc_ex: VM_COUNTERS_EX = undefined;
            const rc = std.os.windows.ntdll.NtQueryInformationProcess(
                std.os.windows.self_process_handle,
                .ProcessVmCounters,
                &vmc_ex,
                @sizeOf(VM_COUNTERS_EX),
                null,
            );
            if (rc == .SUCCESS) {
                memory_value = @as(f32, @floatFromInt(vmc_ex.WorkingSetSize)) / 1024.0 / 1024.0;
            } else {
                std.log.err("Could not get windows memory information: {any}", .{rc});
            }
        },
        .linux => {
            const file = try std.fs.cwd().openFile("/proc/self/statm", .{});
            defer file.close();

            const data = try file.readToEndAlloc(main.network_stack_allocator, std.math.maxInt(u8));
            defer main.network_stack_allocator.free(data);

            var split_iter = std.mem.split(u8, data, " ");
            _ = split_iter.next(); // total size
            const rss: f32 = @floatFromInt(try std.fmt.parseInt(u32, split_iter.next().?, 0));
            memory_value = rss / 1024.0;
        },
        else => memory_value = 0,
    }

    last_memory_access = main.current_time;
    last_memory_value = memory_value;
    return memory_value;
}

pub fn plusMinus(range: f32) f32 {
    return rng.random().float(f32) * range * 2 - range;
}

pub fn isInBounds(x: f32, y: f32, bound_x: f32, bound_y: f32, bound_w: f32, bound_h: f32) bool {
    return x >= bound_x and x <= bound_x + bound_w and y >= bound_y and y <= bound_y + bound_h;
}

pub fn strlen(str: []const u8) usize {
    var i: usize = 0;
    while (str[i] != 0) : (i += 1) {}
    return i;
}

pub fn halfBound(angle: f32) f32 {
    const mod_angle = @mod(angle, std.math.tau);
    const new_angle = @mod(mod_angle + std.math.tau, std.math.tau);
    return if (new_angle > std.math.pi) new_angle - std.math.tau else new_angle;
}

pub inline fn distSqr(x1: f32, y1: f32, x2: f32, y2: f32) f32 {
    const x_dt = x2 - x1;
    const y_dt = y2 - y1;
    return x_dt * x_dt + y_dt * y_dt;
}

pub inline fn dist(x1: f32, y1: f32, x2: f32, y2: f32) f32 {
    return @sqrt(distSqr(x1, y1, x2, y2));
}
