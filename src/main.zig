const std = @import("std");
const c = @import("c.zig").c;
const gl = @import("opengl.zig");
const Planet = @import("planet.zig");
const Camera = @import("camera.zig");
const zmath = @import("zmath");

const ApplicationError = error{ GLFWInit, GLFWWindowCreation } || gl.Error;

const gravitational_contant = 0.0000000000667430;

const solar_system_width: f32 = 9.024e11;
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

    var sun = try Planet.init(allocator, 1.989e30, 8.957e9, @Vector(2, f32){ 0.0, 0.0 }, [_]f32{ 1.0, 1.0, 0.0, 1.0 });
    // sun.velocity = @Vector(2, f32){ 0.0, 1.34e4 };
    defer sun.deinit();
    var mars = try Planet.init(allocator, 6.417e23, 3.389e9, @Vector(2, f32){
        -2.279e11,
        0.0,
    }, [_]f32{ 0.95, 0.54, 0.21, 1.0 });
    mars.velocity = @Vector(2, f32){ 0.0, 2.4e4 };
    defer mars.deinit();

    var earth = try Planet.init(allocator, 5.972e24, 6.371e9, @Vector(2, f32){
        -1.496e11,
        0.0,
    }, [_]f32{ 0.0, 1.0, 1.0, 1.0 });
    earth.velocity = @Vector(2, f32){ 0.0, 2.98e4 };
    defer earth.deinit();

    var mercury = try Planet.init(allocator, 3.301e23, 2.440e9, @Vector(2, f32){
        -5.791e10,
        0.0,
    }, [_]f32{ 0.71, 0.71, 0.71, 1.0 });
    mercury.velocity = @Vector(2, f32){ 0.0, -4.74e4 };
    defer mercury.deinit();

    var venus = try Planet.init(allocator, 4.867e24, 6.051e9, @Vector(2, f32){
        -1.082e11,
        0.0,
    }, [_]f32{ 165.0 / 255.0, 124.0 / 255.0, 27.0 / 255.0, 1.0 });
    venus.velocity = @Vector(2, f32){ 0.0, 3.5e4 };
    defer venus.deinit();

    var jupiter = try Planet.init(allocator, 1.898e27, 7.051e9, @Vector(2, f32){
        -7.783e11,
        0.0,
    }, [_]f32{ 235.0 / 255.0, 243.0 / 255.0, 246.0 / 255.0, 1.0 });
    jupiter.velocity = @Vector(2, f32){ 0.0, 1.31e4 };
    defer jupiter.deinit();

    const planets = [_]*Planet{ &sun, &mars, &earth, &mercury, &venus, &jupiter };

    const time_accelerator: f32 = 5_000_000.0;
    const max_fps: f32 = 165.0;

    var camera = Camera.init();

    var last_frametime: f64 = 0;
    while (c.glfwWindowShouldClose(window) == c.GLFW_FALSE) {
        const current_frametime = c.glfwGetTime();
        var delta: f32 = @floatCast(current_frametime - last_frametime);

        c.glfwPollEvents();

        c.glfwGetFramebufferSize(window, &width, &height);

        if (delta >= 1.0 / max_fps) {
            camera.update(window, delta, solar_system_width / 5);
            delta *= time_accelerator;

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
                planet.update(delta);
            }

            c.glViewport(0, 0, width, height);

            c.glClearColor(0.0, 0.0, 0.0, 1.0);
            c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);

            const projection = zmath.orthographicRhGl(solar_system_width, solar_system_height, -1.0, 1.0);

            for (planets) |planet| {
                try planet.draw(projection, camera.transform);
            }

            c.glfwSwapBuffers(window);

            last_frametime = current_frametime;
        }
    }
}
