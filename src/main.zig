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

const gravitational_contant = 0.0000000000667430;

const solar_system_width: f32 = 4.024e12;
const solar_system_height: f32 = solar_system_width;
const solar_system_size = @Vector(2, f32){ 8.976e9, 4.995e9 };

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

    var sun = try Planet.init(allocator, 1.989e30, 6.957e10, @Vector(2, f32){ 0.0, 0.0 }, [_]f32{ 1.0, 1.0, 0.0, 1.0 });
    defer sun.deinit();
    var mars = try Planet.init(allocator, 6.39e23, 3.3e10, @Vector(2, f32){
        -2.066e11,
        0.0,
    }, [_]f32{ 0.95, 0.54, 0.21, 1.0 });
    mars.velocity = @Vector(2, f32){ 2.4e4, 2.4e4 };
    defer mars.deinit();
    const planets = [_]*Planet{ &sun, &mars };

    const time_accelerator: f32 = 10_000_000;

    var last_frametime: f64 = 0;
    while (c.glfwWindowShouldClose(window) == c.GLFW_FALSE) {
        const current_frametime = c.glfwGetTime();
        var delta: f32 = @floatCast(current_frametime - last_frametime);
        last_frametime = current_frametime;
        std.log.info("\x1B[2J\x1B[H", .{});
        std.log.info("FPS: {d:2}", .{1000 / delta});
        delta *= time_accelerator;

        c.glfwPollEvents();

        c.glfwGetFramebufferSize(window, &width, &height);

        // const fwidth: f32 = @floatFromInt(width);
        // const fheight: f32 = @floatFromInt(height);

        for (planets) |planet| {
            planet.acceleration = @Vector(2, f32){ 0.0, 0.0 };
            for (planets) |other_planet| {
                if (other_planet != planet) {
                    const distance = planet.position - other_planet.position;
                    const r_squared = distance[0] * distance[0] + distance[1] * distance[1];
                    const distance_magnitude = @sqrt(r_squared);
                    const direction = @Vector(2, f32){ -distance[0] / distance_magnitude, -distance[1] / distance_magnitude };
                    const scalar = gravitational_contant * other_planet.mass / r_squared;
                    planet.acceleration += @Vector(2, f32){ direction[0] * scalar, direction[1] * scalar };
                }
            }
            std.debug.print("acceleration: {}, velocity: {}\n", .{ planet.acceleration, planet.velocity });
            planet.update(delta);
        }

        c.glViewport(0, 0, width, height);

        c.glClearColor(0.0, 0.0, 0.0, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);

        const projection = zmath.orthographicRhGl(solar_system_width, solar_system_height, -1.0, 1.0);
        const view = zmath.mul(zmath.identity(), zmath.translation(0.0, 0.0, -0.9));

        for (planets) |planet| {
            try planet.draw(projection, view);
        }

        c.glfwSwapBuffers(window);
    }
}
