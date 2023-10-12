const std = @import("std");
const ui = @import("ui.zig");
const assets = @import("../assets.zig");
const camera = @import("../camera.zig");
const network = @import("../network.zig");
const xml = @import("../xml.zig");
const main = @import("../main.zig");
const utils = @import("../utils.zig");
const game_data = @import("../game_data.zig");
const map = @import("../map.zig");
const input = @import("../input.zig");
const settings = @import("../settings.zig");
const NineSlice = ui.NineSliceImageData;

pub const Tabs = enum {
    general,
    hotkeys,
    graphics,
    performance,
};

pub const OptionsUi = struct {
    visible: bool = true,
    _allocator: std.mem.Allocator = undefined,
    inited: bool = false,
    selected_tab: Tabs = Tabs.general, //which tab do we start visible on
    main_cont: *ui.DisplayContainer = undefined,
    buttons_cont: *ui.DisplayContainer = undefined,
    tabs_cont: *ui.DisplayContainer = undefined,
    gen_cont: *ui.DisplayContainer = undefined,
    keys_cont: *ui.DisplayContainer = undefined,
    graphics_cont: *ui.DisplayContainer = undefined,
    perf_cont: *ui.DisplayContainer = undefined,

    pub fn init(allocator: std.mem.Allocator) !*OptionsUi {
        var screen = try allocator.create(OptionsUi);
        screen.* = .{ ._allocator = allocator };

        const button_data_base = assets.getUiData("buttonBase", 0);
        const button_data_hover = assets.getUiData("buttonHover", 0);
        const button_data_press = assets.getUiData("buttonPress", 0);
        const text_input_press = assets.getUiData("textInputPress", 0);
        const options_background = assets.getUiData("optionsBackground", 0);

        const button_width = 150;
        const button_height = 50;
        const button_half_width = button_width / 2;
        const button_half_height = button_height / 2;
        const width = camera.screen_width;
        const height = camera.screen_height;
        const buttons_x = width / 2;
        const buttons_y = height - button_height - 50;

        screen.main_cont = try ui.DisplayContainer.create(allocator, .{
            .x = 0,
            .y = 0,
        });

        screen.buttons_cont = try ui.DisplayContainer.create(allocator, .{
            .x = 0,
            .y = buttons_y,
        });

        screen.tabs_cont = try ui.DisplayContainer.create(allocator, .{
            .x = 0,
            .y = 25,
        });

        screen.gen_cont = try ui.DisplayContainer.create(allocator, .{
            .x = 0,
            .y = 100,
            .visible = screen.selected_tab == .general,
        });

        screen.keys_cont = try ui.DisplayContainer.create(allocator, .{
            .x = 0,
            .y = 100,
            .visible = screen.selected_tab == .hotkeys,
        });

        screen.graphics_cont = try ui.DisplayContainer.create(allocator, .{
            .x = 0,
            .y = 100,
            .visible = screen.selected_tab == .graphics,
        });

        screen.perf_cont = try ui.DisplayContainer.create(allocator, .{
            .x = 0,
            .y = 100,
            .visible = screen.selected_tab == .performance,
        });

        _ = try screen.main_cont.createElement(ui.Image, .{ .x = 0, .y = 0, .image_data = .{
            .nine_slice = NineSlice.fromAtlasData(options_background, width, height, 0, 0, 8, 8, 1.0),
        } });

        const buttons_bg_image = try screen.buttons_cont.createElement(ui.Image, .{ .x = 0, .y = -20, .image_data = .{
            .nine_slice = NineSlice.fromAtlasData(text_input_press, width, button_height + 40, 8, 8, 32, 32, 1.0),
        } });

        _ = try screen.buttons_cont.createElement(ui.Button, .{
            .x = buttons_x - button_half_width,
            .y = buttons_bg_image.y + button_half_height,
            .image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(button_data_base, button_width, button_height, 6, 6, 7, 7, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(button_data_hover, button_width, button_height, 6, 6, 7, 7, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(button_data_press, button_width, button_height, 6, 6, 7, 7, 1.0) },
            },
            .text_data = .{
                .text = @constCast("Continue"),
                .size = 16,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .press_callback = closeCallback,
        });

        _ = try screen.buttons_cont.createElement(ui.Button, .{
            .x = width - button_width - 50,
            .y = buttons_bg_image.y + button_half_height,
            .image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(button_data_base, button_width, button_height, 6, 6, 7, 7, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(button_data_hover, button_width, button_height, 6, 6, 7, 7, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(button_data_press, button_width, button_height, 6, 6, 7, 7, 1.0) },
            },
            .text_data = .{
                .text = @constCast("Disconnect"),
                .size = 16,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .press_callback = disconnectCallback,
        });

        _ = try screen.buttons_cont.createElement(ui.Button, .{
            .x = 50,
            .y = buttons_bg_image.y + button_half_height,
            .image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(button_data_base, button_width, button_height, 6, 6, 7, 7, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(button_data_hover, button_width, button_height, 6, 6, 7, 7, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(button_data_press, button_width, button_height, 6, 6, 7, 7, 1.0) },
            },
            .text_data = .{
                .text = @constCast("Reset to default"),
                .size = 16,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .press_callback = resetToDefaultsCallback,
        });

        _ = try screen.main_cont.createElement(ui.UiText, .{ .x = buttons_x - 76, .y = 25, .text_data = .{
            .text = @constCast("Options"),
            .size = 32,
            .text_type = .bold,
            .backing_buffer = try allocator.alloc(u8, 8),
        } });

        var tab_x_offset: f32 = 50;
        const tab_y: f32 = 50;

        _ = try screen.tabs_cont.createElement(ui.Button, .{
            .x = tab_x_offset,
            .y = tab_y,
            .visible = screen.visible,
            .image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(button_data_base, button_width, button_height, 6, 6, 7, 7, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(button_data_hover, button_width, button_height, 6, 6, 7, 7, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(button_data_press, button_width, button_height, 6, 6, 7, 7, 1.0) },
            },
            .text_data = .{
                .text = @constCast("General"),
                .size = 16,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .press_callback = generalTabCallback,
        });

        tab_x_offset += button_width;

        _ = try screen.tabs_cont.createElement(ui.Button, .{
            .x = tab_x_offset,
            .y = tab_y,
            .visible = screen.visible,
            .image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(button_data_base, button_width, button_height, 6, 6, 7, 7, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(button_data_hover, button_width, button_height, 6, 6, 7, 7, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(button_data_press, button_width, button_height, 6, 6, 7, 7, 1.0) },
            },
            .text_data = .{
                .text = @constCast("Hotkeys"),
                .size = 16,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .press_callback = hotkeysTabCallback,
        });

        tab_x_offset += button_width;

        _ = try screen.tabs_cont.createElement(ui.Button, .{
            .x = tab_x_offset,
            .y = tab_y,
            .visible = screen.visible,
            .image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(button_data_base, button_width, button_height, 6, 6, 7, 7, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(button_data_hover, button_width, button_height, 6, 6, 7, 7, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(button_data_press, button_width, button_height, 6, 6, 7, 7, 1.0) },
            },
            .text_data = .{
                .text = @constCast("Graphics"),
                .size = 16,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .press_callback = graphicsTabCallback,
        });

        tab_x_offset += button_width;

        _ = try screen.tabs_cont.createElement(ui.Button, .{
            .x = tab_x_offset,
            .y = tab_y,
            .visible = screen.visible,
            .image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(button_data_base, button_width, button_height, 6, 6, 7, 7, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(button_data_hover, button_width, button_height, 6, 6, 7, 7, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(button_data_press, button_width, button_height, 6, 6, 7, 7, 1.0) },
            },
            .text_data = .{
                .text = @constCast("Performance"),
                .size = 16,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .press_callback = performanceTabCallback,
        });

        //general tab

        const key_width: f32 = 50;
        const key_y_spacer: f32 = button_height;
        const key_title_size: f32 = 18;
        var key_y: f32 = key_y_spacer;
        const magic: f32 = key_title_size * 9;
        const column_0: f32 = key_width + magic;
        const column_1: f32 = column_0 + column_0;
        //cosnt column_2: f32 = column_0 + column_1; //If more columns are needed
        //const column_3: f32 = column_0 + column_2;

        _ = try screen.gen_cont.createElement(ui.KeyMapper, .{
            .x = column_0,
            .y = key_y,
            .image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(button_data_base, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(button_data_hover, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(button_data_press, key_width, button_height, 6, 6, 7, 7, 1.0) },
            },
            .text_data = .{
                .text = @constCast(settings.move_up.getName()),
                .size = 16,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .title_text_data = .{
                .text = @constCast("Move up"),
                .size = key_title_size,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .key = settings.move_up.getKey(),
            .settings_button = &settings.move_up,
            .set_key_callback = keyCallback,
        });

        key_y += key_y_spacer;

        _ = try screen.gen_cont.createElement(ui.KeyMapper, .{
            .x = column_0,
            .y = key_y,
            .image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(button_data_base, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(button_data_hover, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(button_data_press, key_width, button_height, 6, 6, 7, 7, 1.0) },
            },
            .text_data = .{
                .text = @constCast(settings.move_down.getName()),
                .size = 16,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .title_text_data = .{
                .text = @constCast("Move down"),
                .size = key_title_size,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .key = settings.move_down.getKey(),
            .settings_button = &settings.move_down,
            .set_key_callback = keyCallback,
        });

        key_y += key_y_spacer;

        _ = try screen.gen_cont.createElement(ui.KeyMapper, .{
            .x = column_0,
            .y = key_y,
            .image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(button_data_base, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(button_data_hover, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(button_data_press, key_width, button_height, 6, 6, 7, 7, 1.0) },
            },
            .text_data = .{
                .text = @constCast(settings.move_right.getName()),
                .size = 16,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .title_text_data = .{
                .text = @constCast("Move right"),
                .size = key_title_size,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .key = settings.move_right.getKey(),
            .settings_button = &settings.move_right,
            .set_key_callback = keyCallback,
        });

        key_y += key_y_spacer;

        _ = try screen.gen_cont.createElement(ui.KeyMapper, .{
            .x = column_0,
            .y = key_y,
            .image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(button_data_base, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(button_data_hover, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(button_data_press, key_width, button_height, 6, 6, 7, 7, 1.0) },
            },
            .text_data = .{
                .text = @constCast(settings.move_left.getName()),
                .size = 16,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .title_text_data = .{
                .text = @constCast("Move left"),
                .size = key_title_size,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .key = settings.move_left.getKey(),
            .settings_button = &settings.move_left,
            .set_key_callback = keyCallback,
        });

        key_y += key_y_spacer;

        _ = try screen.gen_cont.createElement(ui.KeyMapper, .{
            .x = column_0,
            .y = key_y,
            .image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(button_data_base, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(button_data_hover, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(button_data_press, key_width, button_height, 6, 6, 7, 7, 1.0) },
            },
            .text_data = .{
                .text = @constCast(settings.rotate_left.getName()),
                .size = 16,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .title_text_data = .{
                .text = @constCast("Rotate left"),
                .size = key_title_size,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .key = settings.rotate_left.getKey(),
            .settings_button = &settings.rotate_left,
            .set_key_callback = keyCallback,
        });

        key_y += key_y_spacer;

        _ = try screen.gen_cont.createElement(ui.KeyMapper, .{
            .x = column_0,
            .y = key_y,
            .image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(button_data_base, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(button_data_hover, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(button_data_press, key_width, button_height, 6, 6, 7, 7, 1.0) },
            },
            .text_data = .{
                .text = @constCast(settings.rotate_right.getName()),
                .size = 16,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .title_text_data = .{
                .text = @constCast("Rotate right"),
                .size = key_title_size,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .key = settings.rotate_right.getKey(),
            .settings_button = &settings.rotate_right,
            .set_key_callback = keyCallback,
        });

        key_y += key_y_spacer;

        _ = try screen.gen_cont.createElement(ui.KeyMapper, .{
            .x = column_0,
            .y = key_y,
            .image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(button_data_base, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(button_data_hover, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(button_data_press, key_width, button_height, 6, 6, 7, 7, 1.0) },
            },
            .text_data = .{
                .text = @constCast(settings.escape.getName()),
                .size = 16,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .title_text_data = .{
                .text = @constCast("Escape"),
                .size = key_title_size,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .key = settings.escape.getKey(),
            .settings_button = &settings.escape,
            .set_key_callback = keyCallback,
        });

        key_y += key_y_spacer;

        _ = try screen.gen_cont.createElement(ui.KeyMapper, .{
            .x = column_0,
            .y = key_y,
            .image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(button_data_base, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(button_data_hover, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(button_data_press, key_width, button_height, 6, 6, 7, 7, 1.0) },
            },
            .text_data = .{
                .text = @constCast(settings.interact.getName()),
                .size = 16,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .title_text_data = .{
                .text = @constCast("Interact"),
                .size = key_title_size,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .key = settings.interact.getKey(),
            .mouse = settings.interact.getMouse(),
            .settings_button = &settings.interact,
            .set_key_callback = keyCallback,
        });

        key_y = key_y_spacer;

        _ = try screen.gen_cont.createElement(ui.KeyMapper, .{
            .x = column_1,
            .y = key_y,
            .image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(button_data_base, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(button_data_hover, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(button_data_press, key_width, button_height, 6, 6, 7, 7, 1.0) },
            },
            .text_data = .{
                .text = @constCast(settings.shoot.getName()),
                .size = 16,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .title_text_data = .{
                .text = @constCast("Shoot"),
                .size = key_title_size,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .key = settings.shoot.getKey(),
            .mouse = settings.shoot.getMouse(),
            .settings_button = &settings.shoot,
            .set_key_callback = keyCallback,
        });

        key_y += key_y_spacer;

        _ = try screen.gen_cont.createElement(ui.KeyMapper, .{
            .x = column_1,
            .y = key_y,
            .image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(button_data_base, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(button_data_hover, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(button_data_press, key_width, button_height, 6, 6, 7, 7, 1.0) },
            },
            .text_data = .{
                .text = @constCast(settings.ability.getName()),
                .size = 16,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .title_text_data = .{
                .text = @constCast("Ability"),
                .size = key_title_size,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .key = settings.ability.getKey(),
            .mouse = settings.ability.getMouse(),
            .settings_button = &settings.ability,
            .set_key_callback = keyCallback,
        });

        key_y += key_y_spacer;

        _ = try screen.gen_cont.createElement(ui.KeyMapper, .{
            .x = column_1,
            .y = key_y,
            .image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(button_data_base, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(button_data_hover, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(button_data_press, key_width, button_height, 6, 6, 7, 7, 1.0) },
            },
            .text_data = .{
                .text = @constCast(settings.toggle_centering.getName()),
                .size = 16,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .title_text_data = .{
                .text = @constCast("Toggle Centering"),
                .size = key_title_size,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .key = settings.toggle_centering.getKey(),
            .mouse = settings.toggle_centering.getMouse(),
            .settings_button = &settings.toggle_centering,
            .set_key_callback = keyCallback,
        });

        key_y += key_y_spacer;

        _ = try screen.gen_cont.createElement(ui.KeyMapper, .{
            .x = column_1,
            .y = key_y,
            .image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(button_data_base, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(button_data_hover, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(button_data_press, key_width, button_height, 6, 6, 7, 7, 1.0) },
            },
            .text_data = .{
                .text = @constCast(settings.reset_camera.getName()),
                .size = 16,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .title_text_data = .{
                .text = @constCast("Reset Camera"),
                .size = key_title_size,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .key = settings.reset_camera.getKey(),
            .mouse = settings.reset_camera.getMouse(),
            .settings_button = &settings.reset_camera,
            .set_key_callback = keyCallback,
        });

        key_y += key_y_spacer;

        _ = try screen.gen_cont.createElement(ui.KeyMapper, .{
            .x = column_1,
            .y = key_y,
            .image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(button_data_base, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(button_data_hover, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(button_data_press, key_width, button_height, 6, 6, 7, 7, 1.0) },
            },
            .text_data = .{
                .text = @constCast(settings.toggle_stats.getName()),
                .size = 16,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .title_text_data = .{
                .text = @constCast("Toggle Stats"),
                .size = key_title_size,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .key = settings.toggle_stats.getKey(),
            .mouse = settings.toggle_stats.getMouse(),
            .settings_button = &settings.toggle_stats,
            .set_key_callback = keyCallback,
        });
        //keys tab

        key_y = key_y_spacer;

        _ = try screen.keys_cont.createElement(ui.KeyMapper, .{
            .x = column_0,
            .y = key_y,
            .image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(button_data_base, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(button_data_hover, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(button_data_press, key_width, button_height, 6, 6, 7, 7, 1.0) },
            },
            .text_data = .{
                .text = @constCast(settings.inv_0.getName()),
                .size = 16,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .title_text_data = .{
                .text = @constCast("Slot 0"),
                .size = key_title_size,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .key = settings.inv_0.getKey(),
            .mouse = settings.inv_0.getMouse(),
            .settings_button = &settings.inv_0,
            .set_key_callback = keyCallback,
        });

        key_y += key_y_spacer;

        _ = try screen.keys_cont.createElement(ui.KeyMapper, .{
            .x = column_0,
            .y = key_y,
            .image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(button_data_base, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(button_data_hover, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(button_data_press, key_width, button_height, 6, 6, 7, 7, 1.0) },
            },
            .text_data = .{
                .text = @constCast(settings.inv_1.getName()),
                .size = 16,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .title_text_data = .{
                .text = @constCast("Slot 1"),
                .size = key_title_size,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .key = settings.inv_1.getKey(),
            .mouse = settings.inv_1.getMouse(),
            .settings_button = &settings.inv_1,
            .set_key_callback = keyCallback,
        });

        key_y += key_y_spacer;

        _ = try screen.keys_cont.createElement(ui.KeyMapper, .{
            .x = column_0,
            .y = key_y,
            .image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(button_data_base, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(button_data_hover, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(button_data_press, key_width, button_height, 6, 6, 7, 7, 1.0) },
            },
            .text_data = .{
                .text = @constCast(settings.inv_2.getName()),
                .size = 16,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .title_text_data = .{
                .text = @constCast("Slot 2"),
                .size = key_title_size,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .key = settings.inv_2.getKey(),
            .mouse = settings.inv_2.getMouse(),
            .settings_button = &settings.inv_2,
            .set_key_callback = keyCallback,
        });

        key_y += key_y_spacer;

        _ = try screen.keys_cont.createElement(ui.KeyMapper, .{
            .x = column_0,
            .y = key_y,
            .image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(button_data_base, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(button_data_hover, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(button_data_press, key_width, button_height, 6, 6, 7, 7, 1.0) },
            },
            .text_data = .{
                .text = @constCast(settings.inv_3.getName()),
                .size = 16,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .title_text_data = .{
                .text = @constCast("Slot 3"),
                .size = key_title_size,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .key = settings.inv_3.getKey(),
            .mouse = settings.inv_3.getMouse(),
            .settings_button = &settings.inv_3,
            .set_key_callback = keyCallback,
        });

        key_y += key_y_spacer;

        _ = try screen.keys_cont.createElement(ui.KeyMapper, .{
            .x = column_0,
            .y = key_y,
            .image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(button_data_base, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(button_data_hover, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(button_data_press, key_width, button_height, 6, 6, 7, 7, 1.0) },
            },
            .text_data = .{
                .text = @constCast(settings.inv_4.getName()),
                .size = 16,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .title_text_data = .{
                .text = @constCast("Slot 4"),
                .size = key_title_size,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .key = settings.inv_4.getKey(),
            .mouse = settings.inv_4.getMouse(),
            .settings_button = &settings.inv_4,
            .set_key_callback = keyCallback,
        });

        key_y += key_y_spacer;

        _ = try screen.keys_cont.createElement(ui.KeyMapper, .{
            .x = column_0,
            .y = key_y,
            .image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(button_data_base, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(button_data_hover, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(button_data_press, key_width, button_height, 6, 6, 7, 7, 1.0) },
            },
            .text_data = .{
                .text = @constCast(settings.inv_5.getName()),
                .size = 16,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .title_text_data = .{
                .text = @constCast("Slot 5"),
                .size = key_title_size,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .key = settings.inv_5.getKey(),
            .mouse = settings.inv_5.getMouse(),
            .settings_button = &settings.inv_5,
            .set_key_callback = keyCallback,
        });

        key_y += key_y_spacer;

        _ = try screen.keys_cont.createElement(ui.KeyMapper, .{
            .x = column_0,
            .y = key_y,
            .image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(button_data_base, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(button_data_hover, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(button_data_press, key_width, button_height, 6, 6, 7, 7, 1.0) },
            },
            .text_data = .{
                .text = @constCast(settings.inv_6.getName()),
                .size = 16,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .title_text_data = .{
                .text = @constCast("Slot 6"),
                .size = key_title_size,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .key = settings.inv_6.getKey(),
            .mouse = settings.inv_6.getMouse(),
            .settings_button = &settings.inv_6,
            .set_key_callback = keyCallback,
        });

        key_y += key_y_spacer;

        _ = try screen.keys_cont.createElement(ui.KeyMapper, .{
            .x = column_0,
            .y = key_y,
            .image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(button_data_base, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(button_data_hover, key_width, button_height, 6, 6, 7, 7, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(button_data_press, key_width, button_height, 6, 6, 7, 7, 1.0) },
            },
            .text_data = .{
                .text = @constCast(settings.inv_7.getName()),
                .size = 16,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .title_text_data = .{
                .text = @constCast("Slot 7"),
                .size = key_title_size,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .key = settings.inv_7.getKey(),
            .mouse = settings.inv_7.getMouse(),
            .settings_button = &settings.inv_7,
            .set_key_callback = keyCallback,
        });
        //graphics tab

        const toggle_data_base_off = assets.getUiData("toggleSliderBaseOff", 0);
        const toggle_data_hover_off = assets.getUiData("toggleSliderHoverOff", 0);
        const toggle_data_press_off = assets.getUiData("toggleSliderPressOff", 0);
        const toggle_data_base_on = assets.getUiData("toggleSliderBaseOn", 0);
        const toggle_data_hover_on = assets.getUiData("toggleSliderHoverOn", 0);
        const toggle_data_press_on = assets.getUiData("toggleSliderPressOn", 0);

        const toggle_width: f32 = 100;
        const toggle_height: f32 = 50;
        var toggle_y: f32 = toggle_height;

        _ = try screen.graphics_cont.createElement(ui.Toggle, .{
            .x = column_0,
            .y = toggle_y,
            .off_image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(toggle_data_base_off, toggle_width, toggle_height, 0, 0, 84, 48, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(toggle_data_hover_off, toggle_width, toggle_height, 0, 0, 84, 48, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(toggle_data_press_off, toggle_width, toggle_height, 0, 0, 84, 48, 1.0) },
            },
            .on_image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(toggle_data_base_on, toggle_width, toggle_height, 0, 0, 84, 48, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(toggle_data_hover_on, toggle_width, toggle_height, 0, 0, 84, 48, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(toggle_data_press_on, toggle_width, toggle_height, 0, 0, 84, 48, 1.0) },
            },
            .text_data = .{ .text = @constCast("V-Sync"), .size = 16, .text_type = .bold, .backing_buffer = try allocator.alloc(u8, 8) },
            .toggled = settings.enable_vsync,
            .state_change = onVSyncToggle,
        });

        toggle_y += toggle_height;

        _ = try screen.graphics_cont.createElement(ui.Toggle, .{
            .x = column_0,
            .y = toggle_y,
            .off_image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(toggle_data_base_off, toggle_width, toggle_height, 0, 0, 84, 48, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(toggle_data_hover_off, toggle_width, toggle_height, 0, 0, 84, 48, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(toggle_data_press_off, toggle_width, toggle_height, 0, 0, 84, 48, 1.0) },
            },
            .on_image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(toggle_data_base_on, toggle_width, toggle_height, 0, 0, 84, 48, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(toggle_data_hover_on, toggle_width, toggle_height, 0, 0, 84, 48, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(toggle_data_press_on, toggle_width, toggle_height, 0, 0, 84, 48, 1.0) },
            },
            .text_data = .{
                .text = @constCast("Lights"),
                .size = 16,
                .text_type = .bold,
                .backing_buffer = try allocator.alloc(u8, 8),
            },
            .toggled = settings.enable_lights,
            .state_change = onLightsToggle,
        });

        toggle_y += toggle_height;

        _ = try screen.graphics_cont.createElement(ui.Toggle, .{
            .x = column_0,
            .y = toggle_y,
            .off_image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(toggle_data_base_off, toggle_width, toggle_height, 0, 0, 84, 48, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(toggle_data_hover_off, toggle_width, toggle_height, 0, 0, 84, 48, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(toggle_data_press_off, toggle_width, toggle_height, 0, 0, 84, 48, 1.0) },
            },
            .on_image_data = .{
                .base = .{ .nine_slice = NineSlice.fromAtlasData(toggle_data_base_on, toggle_width, toggle_height, 0, 0, 84, 48, 1.0) },
                .hover = .{ .nine_slice = NineSlice.fromAtlasData(toggle_data_hover_on, toggle_width, toggle_height, 0, 0, 84, 48, 1.0) },
                .press = .{ .nine_slice = NineSlice.fromAtlasData(toggle_data_press_on, toggle_width, toggle_height, 0, 0, 84, 48, 1.0) },
            },
            .text_data = .{ .text = @constCast("Glow"), .size = 16, .text_type = .bold, .backing_buffer = try allocator.alloc(u8, 8) },
            .toggled = settings.enable_glow,
            .state_change = onGlowToggle,
        });

        screen.inited = true;
        return screen;
    }

    pub fn deinit(self: *OptionsUi) void {
        while (!ui.ui_lock.tryLock()) {}
        defer ui.ui_lock.unlock();

        self.gen_cont.destroy();
        self.buttons_cont.destroy();
        self.tabs_cont.destroy();
        self.keys_cont.destroy();
        self.perf_cont.destroy();
        self.graphics_cont.destroy();
        self.main_cont.destroy();

        self._allocator.destroy(self);
    }

    fn onVSyncToggle(self: *ui.Toggle) void {
        settings.enable_vsync = self.toggled;
    }

    fn onLightsToggle(self: *ui.Toggle) void {
        settings.enable_lights = self.toggled;
    }

    fn onGlowToggle(self: *ui.Toggle) void {
        settings.enable_glow = self.toggled;
    }

    fn keyCallback(self: *ui.KeyMapper) void {
        if (self.key == .unknown and self.mouse == .unknown) { //true if player presses esc during key setting
            self.settings_button.* = settings.Button{ .key = .unknown };
        } else if (self.key == .unknown) {
            self.settings_button.* = settings.Button{ .mouse = self.mouse };
        } else if (self.mouse == .unknown) {
            self.settings_button.* = settings.Button{ .key = self.key };
        }

        //var newBut = settings.Button{ .key = self.key };
        //but = newBut;

        //self.settings_button.key = self.key;
    }

    fn closeCallback() void {
        ui.hideOptions();
    }

    fn resetToDefaultsCallback() void {
        settings.resetToDefault();
    }

    fn generalTabCallback() void {
        switchTab(.general);
    }

    fn graphicsTabCallback() void {
        switchTab(.graphics);
    }

    fn hotkeysTabCallback() void {
        switchTab(.hotkeys);
    }

    fn performanceTabCallback() void {
        switchTab(.performance);
    }

    fn disconnectCallback() void {
        closeCallback();
        main.disconnect();
    }

    pub fn switchTab(tab: Tabs) void {
        ui.options.selected_tab = tab;
        ui.options.gen_cont.visible = tab == .general;
        ui.options.keys_cont.visible = tab == .hotkeys;
        ui.options.graphics_cont.visible = tab == .graphics;
        ui.options.perf_cont.visible = tab == .performance;
    }
};