const std = @import("std");
const c = @import("c.zig").c;
const gl = @import("opengl.zig");

const ApplicationError = error{ GLFWInit, GLFWWindowCreation } || gl.Error;

const vertexShaderSource: []const u8 = @embedFile("./vertex.glsl");
const fragmentShaderSource: []const u8 = @embedFile("./fragment.glsl");

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
    const window = c.glfwCreateWindow(width, height, "lexis", null, null) orelse return ApplicationError.GLFWWindowCreation;
    c.glfwMakeContextCurrent(window);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var vertex_shader = try gl.Shader.init(vertexShaderSource, .vertex, allocator);
    var fragment_shader = try gl.Shader.init(fragmentShaderSource, .fragment, allocator);
    var shader_program = gl.ShaderProgram.init();
    defer shader_program.deinit();
    shader_program.attach(&vertex_shader);
    shader_program.attach(&fragment_shader);
    try shader_program.link();
    vertex_shader.deinit();
    fragment_shader.deinit();

    var vertex_array_object_id: c_uint = undefined;
    c.glGenVertexArrays(1, &vertex_array_object_id);
    defer c.glDeleteVertexArrays(1, &vertex_array_object_id);

    c.glBindVertexArray(vertex_array_object_id);
    const vertices = [_]f32{
        0.5,  0.5,
        0.5,  -0.5,
        -0.5, 0.5,
        -0.5, -0.5,
    };
    var vertex_buffer_object_id: c_uint = undefined;
    c.glGenBuffers(1, &vertex_buffer_object_id);
    defer c.glDeleteVertexArrays(1, &vertex_buffer_object_id);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vertex_buffer_object_id);
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), @ptrCast(@alignCast(&vertices)), c.GL_STATIC_DRAW);
    c.glVertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, 0, null);
    c.glEnableVertexAttribArray(0);
    c.glBindVertexArray(0);

    var last_frametime: f64 = 0;
    while (c.glfwWindowShouldClose(window) == c.GLFW_FALSE) {
        const current_frametime = c.glfwGetTime();
        const delta = current_frametime - last_frametime;
        last_frametime = current_frametime;
        std.log.info("\x1B[2J\x1B[H", .{});
        std.log.info("FPS: {d:6.5}", .{1000 / delta});

        c.glfwGetFramebufferSize(window, &width, &height);
        c.glViewport(0, 0, width, height);

        c.glClearColor(1.0, 1.0, 1.0, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        shader_program.use();
        try shader_program.setUniform("backgroundColor", .{ 0.4, 0.8, 0.2, 1.0 });
        std.log.info("{}", .{std.math.sin(current_frametime)});
        try shader_program.setUniform("offset", @as(f32, @floatCast(std.math.sin(current_frametime) / 2)));

        c.glBindVertexArray(vertex_array_object_id);
        c.glDrawArrays(c.GL_TRIANGLE_STRIP, 0, 4);
        c.glBindVertexArray(0);

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }

    c.glDeleteVertexArrays(1, &vertex_array_object_id);
    c.glDeleteBuffers(1, &vertex_buffer_object_id);
}
