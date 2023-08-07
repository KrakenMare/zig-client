const zglfw = @import("zglfw");
const settings = @import("settings.zig");
const std = @import("std");
const map = @import("map.zig");
const main = @import("main.zig");
const camera = @import("camera.zig");

var move_up: f32 = 0.0;
var move_down: f32 = 0.0;
var move_left: f32 = 0.0;
var move_right: f32 = 0.0;
var rotate_left: i8 = 0;
var rotate_right: i8 = 0;

pub var attacking: bool = false;
pub var walking: f32 = 1.0;
pub var rotate: i8 = 0;
pub var mouse_x: f64 = 0.0;
pub var mouse_y: f64 = 0.0;

inline fn keyPress(key: zglfw.Key) void {
    if (key == settings.move_up.getKey()) {
        move_up = 1.0;
    } else if (key == settings.move_down.getKey()) {
        move_down = 1.0;
    } else if (key == settings.move_left.getKey()) {
        move_left = 1.0;
    } else if (key == settings.move_right.getKey()) {
        move_right = 1.0;
    } else if (key == settings.rotate_left.getKey()) {
        rotate_left = 1;
    } else if (key == settings.rotate_right.getKey()) {
        rotate_right = 1;
    } else if (key == settings.walk.getKey()) {
        walking = 0.5;
    } else if (key == settings.reset_camera.getKey()) {
        camera.angle = 0;
    } else if (key == settings.shoot.getKey()) {
        attacking = true;
    }
}

inline fn keyRelease(key: zglfw.Key) void {
    if (key == settings.move_up.getKey()) {
        move_up = 0.0;
    } else if (key == settings.move_down.getKey()) {
        move_down = 0.0;
    } else if (key == settings.move_left.getKey()) {
        move_left = 0.0;
    } else if (key == settings.move_right.getKey()) {
        move_right = 0.0;
    } else if (key == settings.rotate_left.getKey()) {
        rotate_left = 0;
    } else if (key == settings.rotate_right.getKey()) {
        rotate_right = 0;
    } else if (key == settings.walk.getKey()) {
        walking = 1.0;
    } else if (key == settings.shoot.getKey()) {
        attacking = false;
    }
}

inline fn mousePress(button: zglfw.MouseButton) void {
    if (button == settings.move_up.getMouse()) {
        move_up = 1.0;
    } else if (button == settings.move_down.getMouse()) {
        move_down = 1.0;
    } else if (button == settings.move_left.getMouse()) {
        move_left = 1.0;
    } else if (button == settings.move_right.getMouse()) {
        move_right = 1.0;
    } else if (button == settings.rotate_left.getMouse()) {
        rotate_left = 1;
    } else if (button == settings.rotate_right.getMouse()) {
        rotate_right = 1;
    } else if (button == settings.walk.getMouse()) {
        walking = 0.5;
    } else if (button == settings.reset_camera.getMouse()) {
        camera.angle = 0;
    } else if (button == settings.shoot.getMouse()) {
        attacking = true;
    }
}

inline fn mouseRelease(button: zglfw.MouseButton) void {
    if (button == settings.move_up.getMouse()) {
        move_up = 0.0;
    } else if (button == settings.move_down.getMouse()) {
        move_down = 0.0;
    } else if (button == settings.move_left.getMouse()) {
        move_left = 0.0;
    } else if (button == settings.move_right.getMouse()) {
        move_right = 0.0;
    } else if (button == settings.rotate_left.getMouse()) {
        rotate_left = 0;
    } else if (button == settings.rotate_right.getMouse()) {
        rotate_right = 0;
    } else if (button == settings.walk.getMouse()) {
        walking = 1.0;
    } else if (button == settings.shoot.getMouse()) {
        attacking = false;
    }
}

pub fn keyEvent(window: *zglfw.Window, key: zglfw.Key, scancode: i32, action: zglfw.Action, mods: zglfw.Mods) callconv(.C) void {
    _ = window;
    _ = scancode;
    _ = mods;

    if (main.current_screen != .in_game)
        return;

    if (action == .press) {
        keyPress(key);
    } else if (action == .release) {
        keyRelease(key);
    }

    updateState();
}

pub fn mouseEvent(window: *zglfw.Window, button: zglfw.MouseButton, action: zglfw.Action, mods: zglfw.Mods) callconv(.C) void {
    _ = window;
    _ = mods;

    if (main.current_screen != .in_game)
        return;

    if (action == .press) {
        mousePress(button);
    } else if (action == .release) {
        mouseRelease(button);
    }

    updateState();
}

pub fn updateState() void {
    rotate = rotate_right - rotate_left;

    // const local_player = map.findPlayer(map.local_player_id);
    // if (local_player != null) {
    //     const y_dt = move_down - move_up;
    //     const x_dt = move_right - move_left;
    //     // random ass -100
    //     local_player.?.move_angle = if (y_dt == 0 and x_dt == 0) -100 else std.math.atan2(f32, y_dt, x_dt);
    //     local_player.?.visual_move_angle = local_player.?.move_angle;
    //     local_player.?.speed_mult = walking;
    // }

    // if (local_player != null and attacking) {
    //     const y: f32 = @floatCast(mouse_y);
    //     const x: f32 = @floatCast(mouse_x);
    //     const shoot_angle = std.math.atan2(f32, y - camera.screen_height / 2.0, x - camera.screen_width / 2.0) + camera.angle;
    //     local_player.?.shoot(shoot_angle, main.current_time);
    // }
}

pub fn mouseMoveEvent(window: *zglfw.Window, xpos: f64, ypos: f64) callconv(.C) void {
    _ = window;

    mouse_x = xpos;
    mouse_y = ypos;
}