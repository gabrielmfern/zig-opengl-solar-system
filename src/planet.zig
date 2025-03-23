const std = @import("std");
const gl = @import("opengl.zig");
const RectangleVertexArray = @import("main.zig").RectangleVertexArray;
const zmath = @import("zmath");

position: @Vector(2, f32),
radius: f32,
color: [4]f32,

velocity: @Vector(2, f32),
acceleration: @Vector(2, f32),

mass: f32,

shader_program: gl.ShaderProgram,

circle_array_buffer: gl.ArrayBuffer,
circle_vertex_array: gl.VertexArray,

const Self = @This();

const vertexShaderSource: []const u8 = @embedFile("./planet/vertex.glsl");
const fragmentShaderSource: []const u8 = @embedFile("./planet/fragment.glsl");

const circle_vertex_count = 1000;

pub fn init(allocator: std.mem.Allocator, mass: f32, radius: f32, position: @Vector(2, f32), color: [4]f32) !Self {
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

    return Self{ .position = position, .radius = radius, .velocity = @Vector(2, f32){ 0.0, 0.0 }, .acceleration = @Vector(2, f32){ 0.0, 0.0 }, .shader_program = shader_program, .circle_array_buffer = array_buffer, .circle_vertex_array = vertex_array, .mass = mass, .color = color };
}

pub fn deinit(self: *Self) void {
    self.shader_program.deinit();

    self.circle_vertex_array.deinit();
    self.circle_array_buffer.deinit();
}

pub fn update(self: *Self, delta: f32) void {
    const delta_vector = @Vector(2, f32){ delta, delta };
    self.velocity = self.velocity + self.acceleration * delta_vector;
    self.position = self.position + self.velocity * delta_vector;
}

pub fn draw(self: *Self, projection: zmath.Mat, view: zmath.Mat) !void {
    var transform = zmath.identity();
    transform = zmath.mul(transform, zmath.scaling(self.radius, self.radius, 1.0));
    transform = zmath.mul(transform, zmath.translation(self.position[0], self.position[1], 0.0));

    self.shader_program.use();

    try self.shader_program.setUniform("color", self.color);

    try self.shader_program.setUniform("projection", projection);
    try self.shader_program.setUniform("view", view);
    try self.shader_program.setUniform("transform", transform);
    self.circle_vertex_array.draw(.triangle_fan, 0, circle_vertex_count);
}
