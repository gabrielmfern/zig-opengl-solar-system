const std = @import("std");
const c = @import("c.zig").c;
const gl = @import("opengl.zig");
const Planet = @import("planet.zig");
const zmath = @import("zmath");

const ApplicationError = error{ GLFWInit, GLFWWindowCreation } || gl.Error;

pub const RectangleVertexArray = struct {
    id: c_uint,
    vertex_buffer_id: c_uint,

    fn init() RectangleVertexArray {
        var id: c_uint = undefined;
        c.glGenVertexArrays(1, &id);

        c.glBindVertexArray(id);

        var vertex_buffer_id: c_uint = undefined;
        c.glGenBuffers(1, &vertex_buffer_id);

        c.glBindBuffer(c.GL_ARRAY_BUFFER, vertex_buffer_id);
        const vertices = [_]f32{
            0.5,  0.5,
            0.5,  -0.5,
            -0.5, 0.5,
            -0.5, -0.5,
        };
        c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), @ptrCast(@alignCast(&vertices)), c.GL_STATIC_DRAW);
        c.glVertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, 0, null);
        c.glEnableVertexAttribArray(0);
        c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);

        c.glBindVertexArray(0);

        return RectangleVertexArray{ .id = id, .vertex_buffer_id = vertex_buffer_id };
    }

    pub fn draw(self: RectangleVertexArray) void {
        c.glBindVertexArray(self.id);
        c.glDrawArrays(c.GL_TRIANGLE_STRIP, 0, 4);
        c.glBindVertexArray(0);
    }

    fn deinit(self: RectangleVertexArray) void {
        c.glDeleteVertexArrays(1, &self.id);
        c.glDeleteBuffers(1, &self.vertex_buffer_id);
    }
};

pub fn main() !void {
    if (c.glfwInit() == c.GLFW_FALSE) {
        return ApplicationError.GLFWInit;
    }
    defer c.glfwTerminate();

    var width: i32 = 1280;
    var height: i32 = 720;

    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
    c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GLFW_TRUE);
    c.glfwWindowHint(c.GLFW_OPENGL_DEBUG_CONTEXT, c.GLFW_TRUE);
    const window = c.glfwCreateWindow(width, height, "lexis", null, null) orelse return ApplicationError.GLFWWindowCreation;
    c.glfwMakeContextCurrent(window);
    c.glEnable(c.GL_DEPTH_TEST);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var sun = try Planet.init(
        allocator,
        200,
        0,
        0,
    );
    defer sun.deinit();

    var last_frametime: f64 = 0;
    while (c.glfwWindowShouldClose(window) == c.GLFW_FALSE) {
        const current_frametime = c.glfwGetTime();
        const delta = current_frametime - last_frametime;
        last_frametime = current_frametime;
        std.log.info("\x1B[2J\x1B[H", .{});
        std.log.info("FPS: {d:2}", .{1000 / delta});

        c.glfwPollEvents();

        sun.update();

        c.glfwGetFramebufferSize(window, &width, &height);

        const fwidth: f32 = @floatFromInt(width);
        const fheight: f32 = @floatFromInt(height);

        c.glViewport(0, 0, width, height);

        c.glClearColor(0.0, 0.0, 0.0, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);

        const projection = zmath.orthographicRhGl(fwidth, fheight, 0.0, 1.0);
        const view = zmath.translation(0.0, 0.0, -0.1);

        try sun.draw(projection, view);

        c.glfwSwapBuffers(window);
    }
}
