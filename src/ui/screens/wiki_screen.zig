const std = @import("std");
const ui = @import("../ui.zig");
const assets = @import("../../assets.zig");
const camera = @import("../../camera.zig");
const network = @import("../../network.zig");
const xml = @import("../../xml.zig");
const main = @import("../../main.zig");
const utils = @import("../../utils.zig");
const game_data = @import("../../game_data.zig");
const map = @import("../../map.zig");
const input = @import("../../input.zig");
const screen_controller = @import("screen_controller.zig").ScreenController;
const NineSlice = ui.NineSliceImageData;

pub const WikiScreen = struct {
    inited: bool = false,
    _allocator: std.mem.Allocator = undefined,
    visible: bool = false,
    cont: *ui.DisplayContainer = undefined,
    pub fn init(allocator: std.mem.Allocator, data: WikiScreen) !*WikiScreen {
        var screen = try allocator.create(WikiScreen);
        screen.* = .{ ._allocator = allocator };
        screen.* = data;

        var width: f32 = camera.screen_width;
        var height: f32 = camera.screen_height;
        var half_width: f32 = width / 2;
        var half_height: f32 = height / 2;

        const container_data = assets.getUiData("containerView", 0);
        screen.cont = try ui.DisplayContainer.create(allocator, .{
            .x = 0,
            .y = 0,
            .visible = screen.visible,
        });

        _ = try screen.cont.createElement(ui.Image, .{
            .x = 0,
            .y = 0,
            .image_data = .{ .normal = .{ .atlas_data = container_data } },
        });

        const button_data_base = assets.getUiData("buttonBase", 0);
        const button_data_hover = assets.getUiData("buttonHover", 0);
        const button_data_press = assets.getUiData("buttonPress", 0);

        var actual_width = container_data.texWRaw() - 10;
        var actual_height = container_data.texHRaw() - 10;

        _ = try screen.cont.createElement(ui.Button, .{
            .x = half_width,
            .y = half_height,
            .image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(button_data_base, actual_width, actual_height, 6, 6, 7, 7, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(button_data_hover, actual_width, actual_height, 6, 6, 7, 7, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(button_data_press, actual_width, actual_height, 6, 6, 7, 7, 1.0) },
            },
            .text_data = .{
                .text = @constCast("Close"),
                .size = 16,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .press_callback = closeCallback,
        });

        screen.inited = true;
        return screen;
    }

    pub fn setVisible(self: *WikiScreen, val: bool) void {
        self.cont.visible = val;
    }

    pub fn deinit(self: *WikiScreen) void {
        while (!ui.ui_lock.tryLock()) {}
        defer ui.ui_lock.unlock();

        self.cont.destroy();

        self._allocator.destroy(self);
    }

    fn closeCallback() void {
        ui.current_screen.in_game.screen_controller.hideScreens();
    }

    pub fn resize(_: *WikiScreen, _: f32, _: f32) void {}
};
