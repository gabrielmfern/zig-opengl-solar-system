const std = @import("std");
const gl = @import("opengl.zig");
const RectangleVertexArray = @import("main.zig").RectangleVertexArray;

x: f32,
y: f32,
radius: f32,

velocity: f32,
acceleration: f32,

shader_program: gl.ShaderProgram,

circle_array_buffer: gl.ArrayBuffer,
circle_vertex_array: gl.VertexArray,

const Self = @This();

const vertexShaderSource: []const u8 = @embedFile("./planet/vertex.glsl");
const fragmentShaderSource: []const u8 = @embedFile("./planet/fragment.glsl");

const circle_vertex_count = 1000;

pub fn init(allocator: std.mem.Allocator, radius: f32, x: f32, y: f32) !Self {
    var vertex_shader = try gl.Shader.init(vertexShaderSource, .vertex, allocator);
    var fragment_shader = try gl.Shader.init(fragmentShaderSource, .fragment, allocator);

    var shader_program = gl.ShaderProgram.init();
    shader_program.attach(&vertex_shader);
    shader_program.attach(&fragment_shader);
    try shader_program.link();

    vertex_shader.deinit();
    fragment_shader.deinit();

    var vertices: [circle_vertex_count * 2]f32 = undefined;
    const step: f32 = 2.0 * std.math.pi / @as(f32, @floatFromInt(circle_vertex_count));
    for (0..circle_vertex_count) |index| {
        const angle = @as(f32, @floatFromInt(index)) * step;
        const vertex_x = @cos(angle);
        const vertex_y = @sin(angle);
        vertices[2 * index] = vertex_x;
        vertices[2 * index + 1] = vertex_y;
    }
    var array_buffer = try gl.ArrayBuffer.init(.vertex_attributes, vertices, .float, .static_draw);
    var vertex_array = gl.VertexArray.init();
    vertex_array.set_buffer(0, &array_buffer, 2);

    return .{ .x = x, .y = y, .radius = radius, .velocity = 0.0, .acceleration = 0.0, .shader_program = shader_program, .circle_array_buffer = array_buffer, .circle_vertex_array = vertex_array };
}

pub fn deinit(self: *Self) void {
    self.shader_program.deinit();

    self.circle_vertex_array.deinit();
    self.circle_array_buffer.deinit();
}

pub fn update() void {}

pub fn draw(self: *Self) !void {
    self.shader_program.use();
    self.circle_vertex_array.draw(.triangle_fan, 0, circle_vertex_count);
}
