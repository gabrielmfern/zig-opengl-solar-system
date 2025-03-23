const c = @import("c.zig").c;
const zmath = @import("zmath");
const std = @import("std");

transform: zmath.Mat,

const Self = @This();

pub fn init() Self {
    return .{ .transform = zmath.translation(0.0, 0.0, -0.9) };
}

pub fn look_at(self: *Self, position: @Vector(2, f32)) void {
    self.transform = zmath.translation(-position[0], -position[1], -0.9);
}

pub fn update(self: *Self, window: *c.GLFWwindow, delta: f32, movement_speed: f32) void {
    if (c.glfwGetKey(window, c.GLFW_KEY_LEFT) == c.GLFW_PRESS) {
        self.transform = zmath.mul(self.transform, zmath.translation(delta * movement_speed, 0.0, 0.0));
    }

    if (c.glfwGetKey(window, c.GLFW_KEY_RIGHT) == c.GLFW_PRESS) {
        self.transform = zmath.mul(self.transform, zmath.translation(-delta * movement_speed, 0.0, 0.0));
    }

    if (c.glfwGetKey(window, c.GLFW_KEY_UP) == c.GLFW_PRESS) {
        self.transform = zmath.mul(self.transform, zmath.translation(0.0, -delta * movement_speed, 0.0));
    }

    if (c.glfwGetKey(window, c.GLFW_KEY_DOWN) == c.GLFW_PRESS) {
        self.transform = zmath.mul(self.transform, zmath.translation(0.0, delta * movement_speed, 0.0));
    }
}
