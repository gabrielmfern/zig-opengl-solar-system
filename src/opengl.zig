const std = @import("std");
const c = @import("c.zig").c;

pub const Error = error{
    ShaderCompilation,
    ShaderProgramLinking,
    UniformLocatioNotFound,
    InvalidTypeForUniform,
} || std.mem.Allocator.Error;

const OpenGLError = enum(c_uint) {
    no_error = c.GL_NO_ERROR,
    invalid_enum = c.GL_INVALID_ENUM,
    invalid_value = c.GL_INVALID_VALUE,
    invalid_operation = c.GL_INVALID_OPERATION,
    invalid_framebuffer_operation = c.GL_INVALID_FRAMEBUFFER_OPERATION,
    out_of_memory = c.GL_OUT_OF_MEMORY,
    stack_underflow = c.GL_STACK_UNDERFLOW,
    stack_overflow = c.GL_STACK_OVERFLOW,
};

pub fn getError() OpenGLError {
    return @enumFromInt(c.glGetError());
}

pub const ShaderType = enum { vertex, fragment };

pub const Shader = struct {
    source: []const u8,
    shader_type: ShaderType,

    id: c_uint,

    const Self = @This();

    pub fn init(source: []const u8, shader_type: ShaderType, allocator: std.mem.Allocator) Error!Self {
        const shader_id = c.glCreateShader(blk: switch (shader_type) {
            .vertex => break :blk c.GL_VERTEX_SHADER,
            .fragment => break :blk c.GL_FRAGMENT_SHADER,
        });
        c.glShaderSource(shader_id, 1, &source.ptr, &@intCast(source.len));
        c.glCompileShader(shader_id);

        var compilation_status: c_int = undefined;
        c.glGetShaderiv(shader_id, c.GL_COMPILE_STATUS, &compilation_status);
        if (compilation_status != 0) {
            return Shader{ .source = source, .shader_type = shader_type, .id = shader_id };
        }

        var error_size: c.GLint = undefined;
        c.glGetShaderiv(shader_id, c.GL_INFO_LOG_LENGTH, &error_size);

        var message: []u8 = try allocator.alloc(u8, @intCast(error_size));
        defer allocator.destroy(&message);
        c.glGetShaderInfoLog(shader_id, error_size, &error_size, @ptrCast(&message));
        std.log.err("Shader compilation failed with the message: {s}\n", .{message});

        return Error.ShaderCompilation;
    }

    pub fn deinit(self: Self) void {
        c.glDeleteShader(self.id);
    }
};

pub const DrawType = enum(c_uint) { points = c.GL_POINTS, line_strip = c.GL_LINE_STRIP, line_loop = c.GL_LINE_LOOP, lines = c.GL_LINES, line_strip_adjacency = c.GL_LINE_STRIP_ADJACENCY, lines_adjecency = c.GL_LINES_ADJACENCY, triangle_strip = c.GL_TRIANGLE_STRIP, triangle_fan = c.GL_TRIANGLE_FAN, triangles = c.GL_TRIANGLES, triangle_strip_adjacency = c.GL_TRIANGLE_STRIP_ADJACENCY, triangles_adjacency = c.GL_TRIANGLES_ADJACENCY, patches = c.GL_PATCHES };

pub const VertexArray = struct {
    id: c_uint,

    const Self = @This();

    pub fn init() Self {
        var id: c_uint = undefined;
        c.glGenVertexArrays(1, &id);

        return .{ .id = id };
    }

    pub fn set_buffer(self: *Self, index: c_uint, buffer: *ArrayBuffer, component_size: c_int) void {
        self.bind();
        buffer.bind();
        defer buffer.unbind();
        defer self.unbind();

        c.glVertexAttribPointer(index, component_size, @intFromEnum(buffer.value_type), c.GL_FALSE, 0, null);
        c.glEnableVertexAttribArray(index);
    }

    pub fn deinit(self: *Self) void {
        c.glDeleteVertexArrays(1, &self.id);
    }

    pub fn bind(self: *Self) void {
        c.glBindVertexArray(self.id);
    }

    pub fn unbind(self: Self) void {
        _ = self;
        c.glBindVertexArray(0);
    }

    pub fn draw(
        self: *Self,
        draw_type: DrawType,
        start: c_int,
        count: c_int,
    ) void {
        self.bind();
        c.glDrawArrays(@intFromEnum(draw_type), start, count);
        self.unbind();
    }
};

pub const BufferValueType = enum(c_uint) { byte = c.GL_BYTE, unsigned_byte = c.GL_UNSIGNED_BYTE, short = c.GL_SHORT, unsigned_short = c.GL_UNSIGNED_SHORT, int = c.GL_INT, unsinged_int = c.GL_UNSIGNED_INT, half_float = c.GL_HALF_FLOAT, float = c.GL_FLOAT, double = c.GL_DOUBLE, fixed = c.GL_FIXED, int_2_10_10_10_reversed = c.GL_INT_2_10_10_10_REV, unsigned_int_2_10_10_10_reversed = c.GL_UNSIGNED_INT_2_10_10_10_REV, unsigned_int_10f_11f_11f_reversed = c.GL_UNSIGNED_INT_10F_11F_11F_REV };

pub const ShaderValueType = enum(c_uint) {
    float = c.GL_FLOAT,
    vec2 = c.GL_FLOAT_VEC2,
    vec3 = c.GL_FLOAT_VEC3,
    vec4 = c.GL_FLOAT_VEC4,
    double = c.GL_DOUBLE,
    dvec2 = c.GL_DOUBLE_VEC2,
    dvec3 = c.GL_DOUBLE_VEC3,
    dvec4 = c.GL_DOUBLE_VEC4,
    int = c.GL_INT,
    ivec2 = c.GL_INT_VEC2,
    ivec3 = c.GL_INT_VEC3,
    ivec4 = c.GL_INT_VEC4,
    unsigned_int = c.GL_UNSIGNED_INT,
    uvec2 = c.GL_UNSIGNED_INT_VEC2,
    uvec3 = c.GL_UNSIGNED_INT_VEC3,
    uvec4 = c.GL_UNSIGNED_INT_VEC4,
    boolean = c.GL_BOOL,
    bvec2 = c.GL_BOOL_VEC2,
    bvec3 = c.GL_BOOL_VEC3,
    bvec4 = c.GL_BOOL_VEC4,
    mat2 = c.GL_FLOAT_MAT2,
    mat3 = c.GL_FLOAT_MAT3,
    mat4 = c.GL_FLOAT_MAT4,
    mat2x3 = c.GL_FLOAT_MAT2x3,
    mat2x4 = c.GL_FLOAT_MAT2x4,
    mat3x2 = c.GL_FLOAT_MAT3x2,
    mat3x4 = c.GL_FLOAT_MAT3x4,
    mat4x2 = c.GL_FLOAT_MAT4x2,
    mat4x3 = c.GL_FLOAT_MAT4x3,
    dmat2 = c.GL_DOUBLE_MAT2,
    dmat3 = c.GL_DOUBLE_MAT3,
    dmat4 = c.GL_DOUBLE_MAT4,
    dmat2x3 = c.GL_DOUBLE_MAT2x3,
    dmat2x4 = c.GL_DOUBLE_MAT2x4,
    dmat3x2 = c.GL_DOUBLE_MAT3x2,
    dmat3x4 = c.GL_DOUBLE_MAT3x4,
    dmat4x2 = c.GL_DOUBLE_MAT4x2,
    dmat4x3 = c.GL_DOUBLE_MAT4x3,
    sampler1D = c.GL_SAMPLER_1D,
    sampler2D = c.GL_SAMPLER_2D,
    sampler3D = c.GL_SAMPLER_3D,
    samplerCube = c.GL_SAMPLER_CUBE,
    sampler1DShadow = c.GL_SAMPLER_1D_SHADOW,
    sampler2DShadow = c.GL_SAMPLER_2D_SHADOW,
    sampler1DArray = c.GL_SAMPLER_1D_ARRAY,
    sampler2DArray = c.GL_SAMPLER_2D_ARRAY,
    sampler1DArrayShadow = c.GL_SAMPLER_1D_ARRAY_SHADOW,
    sampler2DArrayShadow = c.GL_SAMPLER_2D_ARRAY_SHADOW,
    sampler2DMS = c.GL_SAMPLER_2D_MULTISAMPLE,
    sampler2DMSArray = c.GL_SAMPLER_2D_MULTISAMPLE_ARRAY,
    samplerCubeShadow = c.GL_SAMPLER_CUBE_SHADOW,
    samplerBuffer = c.GL_SAMPLER_BUFFER,
    sampler2DRect = c.GL_SAMPLER_2D_RECT,
    sampler2DRectShadow = c.GL_SAMPLER_2D_RECT_SHADOW,
    isampler1D = c.GL_INT_SAMPLER_1D,
    isampler2D = c.GL_INT_SAMPLER_2D,
    isampler3D = c.GL_INT_SAMPLER_3D,
    isamplerCube = c.GL_INT_SAMPLER_CUBE,
    isampler1DArray = c.GL_INT_SAMPLER_1D_ARRAY,
    isampler2DArray = c.GL_INT_SAMPLER_2D_ARRAY,
    isampler2DMS = c.GL_INT_SAMPLER_2D_MULTISAMPLE,
    isampler2DMSArray = c.GL_INT_SAMPLER_2D_MULTISAMPLE_ARRAY,
    isamplerBuffer = c.GL_INT_SAMPLER_BUFFER,
    isampler2DRect = c.GL_INT_SAMPLER_2D_RECT,
    usampler1D = c.GL_UNSIGNED_INT_SAMPLER_1D,
    usampler2D = c.GL_UNSIGNED_INT_SAMPLER_2D,
    usampler3D = c.GL_UNSIGNED_INT_SAMPLER_3D,
    usamplerCube = c.GL_UNSIGNED_INT_SAMPLER_CUBE,
    usampler1DArray = c.GL_UNSIGNED_INT_SAMPLER_1D_ARRAY,
    usampler2DArray = c.GL_UNSIGNED_INT_SAMPLER_2D_ARRAY,
    usampler2DMS = c.GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE,
    usampler2DMSArray = c.GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE_ARRAY,
    usamplerBuffer = c.GL_UNSIGNED_INT_SAMPLER_BUFFER,
    usampler2DRect = c.GL_UNSIGNED_INT_SAMPLER_2D_RECT,
    image1D = c.GL_IMAGE_1D,
    image2D = c.GL_IMAGE_2D,
    image3D = c.GL_IMAGE_3D,
    image2DRect = c.GL_IMAGE_2D_RECT,
    imageCube = c.GL_IMAGE_CUBE,
    imageBuffer = c.GL_IMAGE_BUFFER,
    image1DArray = c.GL_IMAGE_1D_ARRAY,
    image2DArray = c.GL_IMAGE_2D_ARRAY,
    image2DMS = c.GL_IMAGE_2D_MULTISAMPLE,
    image2DMSArray = c.GL_IMAGE_2D_MULTISAMPLE_ARRAY,
    iimage1D = c.GL_INT_IMAGE_1D,
    iimage2D = c.GL_INT_IMAGE_2D,
    iimage3D = c.GL_INT_IMAGE_3D,
    iimage2DRect = c.GL_INT_IMAGE_2D_RECT,
    iimageCube = c.GL_INT_IMAGE_CUBE,
    iimageBuffer = c.GL_INT_IMAGE_BUFFER,
    iimage1DArray = c.GL_INT_IMAGE_1D_ARRAY,
    iimage2DArray = c.GL_INT_IMAGE_2D_ARRAY,
    iimage2DMS = c.GL_INT_IMAGE_2D_MULTISAMPLE,
    iimage2DMSArray = c.GL_INT_IMAGE_2D_MULTISAMPLE_ARRAY,
    uimage1D = c.GL_UNSIGNED_INT_IMAGE_1D,
    uimage2D = c.GL_UNSIGNED_INT_IMAGE_2D,
    uimage3D = c.GL_UNSIGNED_INT_IMAGE_3D,
    uimage2DRect = c.GL_UNSIGNED_INT_IMAGE_2D_RECT,
    uimageCube = c.GL_UNSIGNED_INT_IMAGE_CUBE,
    uimageBuffer = c.GL_UNSIGNED_INT_IMAGE_BUFFER,
    uimage1DArray = c.GL_UNSIGNED_INT_IMAGE_1D_ARRAY,
    uimage2DArray = c.GL_UNSIGNED_INT_IMAGE_2D_ARRAY,
    uimage2DMS = c.GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE,
    uimage2DMSArray = c.GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE_ARRAY,
    atomic_uint = c.GL_UNSIGNED_INT_ATOMIC_COUNTER,

    pub inline fn from(Value: type) ShaderValueType {
        const type_info = @typeInfo(Value);
        // TODO: add all remaining value types that are supported in glsl
        switch (type_info) {
            .float => |float| {
                if (float.bits == 32) {
                    return ShaderValueType.float;
                } else if (float.bits == 64) {
                    return ShaderValueType.double;
                } else {
                    @compileError("Only 32 bits (float) and 64 bits (double) floating point numbers are supported, found " ++ @typeName(Value));
                }
            },
            .int => |int_type| {
                return switch (int_type.signedness) {
                    .unsigned => ShaderValueType.unsigned_int,
                    .signed => ShaderValueType.int,
                };
            },
            .bool => ShaderValueType.boolean,
            .comptime_float => ShaderValueType.float,
            .array => |array| {
                const child_type_info = @typeInfo(array.child);
                const len = array.len;

                switch (child_type_info) {
                    .float => .{if (child_type_info.float.bits == 32) {
                        switch (len) {
                            2 => return ShaderValueType.vec2,
                            3 => return ShaderValueType.vec3,
                            4 => return ShaderValueType.vec4,
                            else => @compileError("Unsupported array length for float: " ++ @tagName(len)),
                        }
                    } else {
                        switch (len) {
                            2 => return ShaderValueType.dvec2,
                            3 => return ShaderValueType.dvec3,
                            4 => return ShaderValueType.dvec4,
                            else => @compileError("Unsupported array length for double: " ++ @tagName(len)),
                        }
                    }},
                    .int => |int_type| {
                        switch (int_type.signedness) {
                            .unsigned => {
                                switch (len) {
                                    2 => return ShaderValueType.uvec2,
                                    3 => return ShaderValueType.uvec3,
                                    4 => return ShaderValueType.uvec4,
                                    else => @compileError("Unsupported array length for unsigned int: " ++ @tagName(len)),
                                }
                            },
                            .signed => {
                                switch (len) {
                                    2 => return ShaderValueType.ivec2,
                                    3 => return ShaderValueType.ivec3,
                                    4 => return ShaderValueType.ivec4,
                                    else => @compileError("Unsupported array length for signed int: " ++ @tagName(len)),
                                }
                            },
                        }
                    },
                    .bool => switch (len) {
                        2 => return ShaderValueType.bvec2,
                        3 => return ShaderValueType.bvec3,
                        4 => return ShaderValueType.bvec4,
                        else => @compileError("Unsupported array length for bool: " ++ @tagName(len)),
                    },
                    .vector => {
                        const vector = child_type_info.vector;
                        if (vector.child == f32) {
                            switch (vector.len) {
                                2 => switch (len) {
                                    2 => return ShaderValueType.mat2,
                                    3 => return ShaderValueType.mat2x3,
                                    4 => return ShaderValueType.mat2x4,
                                    else => @compileError("Unsupported array length for mat2 column: " ++ @tagName(len)),
                                },
                                3 => switch (len) {
                                    2 => return ShaderValueType.mat3x2,
                                    3 => return ShaderValueType.mat3,
                                    4 => return ShaderValueType.mat3x4,
                                    else => @compileError("Unsupported array length for mat3 column: " ++ @tagName(len)),
                                },
                                4 => switch (len) {
                                    2 => return ShaderValueType.mat4x2,
                                    3 => return ShaderValueType.mat4x3,
                                    4 => return ShaderValueType.mat4,
                                    else => @compileError("Unsupported array length for mat4 column: " ++ @tagName(len)),
                                },
                                else => @compileError("Unsupported vector length: " ++ @tagName(vector.len)),
                            }
                        } else if (vector.child == f64) {
                            switch (vector.len) {
                                2 => switch (len) {
                                    2 => return ShaderValueType.dmat2,
                                    3 => return ShaderValueType.dmat2x3,
                                    4 => return ShaderValueType.dmat2x4,
                                    else => @compileError("Unsupported array length for dmat2 column: " ++ @tagName(len)),
                                },
                                3 => switch (len) {
                                    2 => return ShaderValueType.dmat3x2,
                                    3 => return ShaderValueType.dmat3,
                                    4 => return ShaderValueType.dmat3x4,
                                    else => @compileError("Unsupported array length for dmat3 column: " ++ @tagName(len)),
                                },
                                4 => switch (len) {
                                    2 => return ShaderValueType.dmat4x2,
                                    3 => return ShaderValueType.dmat4x3,
                                    4 => return ShaderValueType.dmat4,
                                    else => @compileError("Unsupported array length for dmat4 column: " ++ @tagName(len)),
                                },
                                else => @compileError("Unsupported vector length: " ++ @tagName(vector.len)),
                            }
                        } else {
                            @compileError("Unsupported matrix component type: " ++ @typeName(vector.child));
                        }
                    },
                    else => @compileError("Unsupported array type: " ++ @typeName(array.child)),
                }
            },
            .vector => |vector| {
                return switch (vector.child) {
                    f32 => switch (vector.len) {
                        2 => ShaderValueType.vec2,
                        3 => ShaderValueType.vec3,
                        4 => ShaderValueType.vec4,
                        else => @compileError("Unsupported vector length: " ++ @tagName(vector.len)),
                    },
                    f64 => switch (vector.len) {
                        2 => ShaderValueType.dvec2,
                        3 => ShaderValueType.dvec3,
                        4 => ShaderValueType.dvec4,
                        else => @compileError("Unsupported vector length: " ++ @tagName(vector.len)),
                    },
                    else => @compileError("Unsupported vector component type: " ++ @typeName(vector.child)),
                };
            },
            else => {
                @compileError("The type " ++ @typeName(Value) ++ " is unsupported in shaders");
            },
        }
    }
};

pub const ArrayBufferType = enum(c_uint) {
    vertex_attributes = c.GL_ARRAY_BUFFER,
    atomic_counter = c.GL_ATOMIC_COUNTER_BUFFER,
    copy_source = c.GL_COPY_READ_BUFFER,
    copy_destination = c.GL_COPY_WRITE_BUFFER,
    indirect_dispatch = c.GL_DISPATCH_INDIRECT_BUFFER,
    indirect_draw = c.GL_DRAW_INDIRECT_BUFFER,
    vertex_indices = c.GL_ELEMENT_ARRAY_BUFFER,
    pixel_read_target = c.GL_PIXEL_PACK_BUFFER,
    text8ure_source = c.GL_PIXEL_UNPACK_BUFFER,
    query_result = c.GL_QUERY_BUFFER,
    shader_storage = c.GL_SHADER_STORAGE_BUFFER,
    texture = c.GL_TEXTURE_BUFFER,
    transform_feedback = c.GL_TRANSFORM_FEEDBACK_BUFFER,
    uniform_storage = c.GL_UNIFORM_BUFFER,
};

pub const ArrayBuffer = struct {
    id: c_uint,
    type: ArrayBufferType,
    value_type: BufferValueType,
    usage: BufferUsage,

    const Self = @This();

    pub const BufferUsage = enum(c_uint) { stream_draw = c.GL_STREAM_DRAW, stream_read = c.GL_STREAM_READ, stream_copy = c.GL_STREAM_COPY, static_draw = c.GL_STATIC_DRAW, static_read = c.GL_STATIC_READ, static_copy = c.GL_STATIC_COPY, dynamic_draw = c.GL_DYNAMIC_DRAW, dynamic_read = c.GL_DYNAMIC_READ, dynamic_copy = c.GL_DYNAMIC_COPY };

    pub fn init(buffer_type: ArrayBufferType, data: anytype, value_type: BufferValueType, usage: BufferUsage) Error!ArrayBuffer {
        var id: c_uint = undefined;
        c.glGenBuffers(1, &id);

        var array_buffer = ArrayBuffer{ .id = id, .type = buffer_type, .value_type = value_type, .usage = usage };
        try array_buffer.set(data, value_type, usage);

        return array_buffer;
    }

    pub fn set(self: *Self, data: anytype, value_type: BufferValueType, usage: BufferUsage) Error!void {
        const Data = @TypeOf(data);
        const data_type_info = @typeInfo(Data);
        if (data_type_info != .array) {
            @compileError("Buffer data should be an array, found " ++ @typeName(Data));
        }

        self.bind();
        c.glBufferData(@intFromEnum(self.type), @sizeOf(Data), @ptrCast(@alignCast(&data)), @intFromEnum(usage));
        const current_error = getError();
        switch (current_error) {
            .no_error => {},
            .invalid_operation => @panic("Tried setting data to the buffer while it was unbound, this is a bug in the code!!"),
            .out_of_memory => return Error.OutOfMemory,
            else => unreachable,
        }
        self.unbind();

        self.usage = usage;
        self.value_type = value_type;
    }

    fn bind(self: *Self) void {
        c.glBindBuffer(@intFromEnum(self.type), self.id);
    }

    fn unbind(self: *Self) void {
        c.glBindBuffer(@intFromEnum(self.type), 0);
    }

    pub fn deinit(self: *Self) void {
        c.glDeleteBuffers(1, &self.id);
    }
};

pub const ShaderProgram = struct {
    id: c_uint,

    const Self = @This();

    pub fn init() Self {
        return .{ .id = c.glCreateProgram() };
    }

    pub fn deinit(self: Self) void {
        c.glDeleteProgram(self.id);
    }

    pub fn attach(self: *Self, shader: *Shader) void {
        c.glAttachShader(self.id, shader.id);
    }

    pub fn getUniformType(self: *Self, location: c_uint) ShaderValueType {
        var name_buf: [512]u8 = undefined;
        var name_length: c_int = undefined;
        var uniform_size: c_int = undefined;
        var uniform_type: c_uint = undefined;
        c.glGetActiveUniform(self.id, location, 512, &name_length, &uniform_size, &uniform_type, &name_buf);

        return @enumFromInt(@as(c_int, @intCast(uniform_type)));
    }

    pub fn setUniform(self: *Self, name: [:0]const u8, value: anytype) Error!void {
        const uniform_location = c.glGetUniformLocation(self.id, name);
        if (uniform_location == -1) {
            return Error.UniformLocatioNotFound;
        }
        const uniform_type = self.getUniformType(@intCast(uniform_location));

        const Value = @TypeOf(value);
        const value_type_info = @typeInfo(Value);
        const value_shader_type = ShaderValueType.from(Value);

        if (value_shader_type != uniform_type) {
            std.log.err("The uniform is of type {} while you passed in {}", .{ uniform_type, value_shader_type });
            return Error.InvalidTypeForUniform;
        }

        switch (value_shader_type) {
            .float => {
                c.glUniform1f(uniform_location, @floatCast(value));
            },
            .double => {
                c.glUniform1d(uniform_location, @floatCast(value));
            },
            .vec2 => {
                if (value_type_info == .array) {
                    c.glUniform2f(uniform_location, @floatCast(value[0]), @floatCast(value[1]));
                } else if (value_type_info == .vector) {
                    c.glUniform2f(uniform_location, @floatCast(value.x), @floatCast(value.y));
                } else {
                    return Error.InvalidValue;
                }
            },
            .vec3 => {
                if (value_type_info == .array) {
                    c.glUniform3f(uniform_location, @floatCast(value[0]), @floatCast(value[1]), @floatCast(value[2]));
                } else if (value_type_info == .vector) {
                    c.glUniform3f(uniform_location, @floatCast(value.x), @floatCast(value.y), @floatCast(value.z));
                } else {
                    return Error.InvalidValue;
                }
            },
            .vec4 => {
                if (value_type_info == .array) {
                    c.glUniform4f(uniform_location, @floatCast(value[0]), @floatCast(value[1]), @floatCast(value[2]), @floatCast(value[3]));
                } else if (value_type_info == .vector) {
                    c.glUniform4f(uniform_location, @floatCast(value.x), @floatCast(value.y), @floatCast(value.z), @floatCast(value.w));
                } else {
                    return Error.InvalidValue;
                }
            },
            .int => {
                c.glUniform1i(uniform_location, @intCast(value));
            },
            .ivec2 => {
                if (value_type_info == .array) {
                    c.glUniform2i(uniform_location, @intCast(value[0]), @intCast(value[1]));
                } else if (value_type_info == .vector) {
                    c.glUniform2i(uniform_location, @intCast(value.x), @intCast(value.y));
                } else {
                    return Error.InvalidValue;
                }
            },
            .ivec3 => {
                if (value_type_info == .array) {
                    c.glUniform3i(uniform_location, @intCast(value[0]), @intCast(value[1]), @intCast(value[2]));
                } else if (value_type_info == .vector) {
                    c.glUniform3i(uniform_location, @intCast(value.x), @intCast(value.y), @intCast(value.z));
                } else {
                    return Error.InvalidValue;
                }
            },
            .ivec4 => {
                if (value_type_info == .array) {
                    c.glUniform4i(uniform_location, @intCast(value[0]), @intCast(value[1]), @intCast(value[2]), @intCast(value[3]));
                } else if (value_type_info == .vector) {
                    c.glUniform4i(uniform_location, @intCast(value.x), @intCast(value.y), @intCast(value.z), @intCast(value.w));
                } else {
                    return Error.InvalidValue;
                }
            },
            .unsigned_int => {
                c.glUniform1ui(uniform_location, @intCast(value));
            },
            .uvec2 => {
                if (value_type_info == .array) {
                    c.glUniform2ui(uniform_location, @intCast(value[0]), @intCast(value[1]));
                } else if (value_type_info == .vector) {
                    c.glUniform2ui(uniform_location, @intCast(value.x), @intCast(value.y));
                } else {
                    return Error.InvalidValue;
                }
            },
            .uvec3 => {
                if (value_type_info == .array) {
                    c.glUniform3ui(uniform_location, @intCast(value[0]), @intCast(value[1]), @intCast(value[2]));
                } else if (value_type_info == .vector) {
                    c.glUniform3ui(uniform_location, @intCast(value.x), @intCast(value.y), @intCast(value.z));
                } else {
                    return Error.InvalidValue;
                }
            },
            .uvec4 => {
                if (value_type_info == .array) {
                    c.glUniform4ui(uniform_location, @intCast(value[0]), @intCast(value[1]), @intCast(value[2]), @intCast(value[3]));
                } else if (value_type_info == .vector) {
                    c.glUniform4ui(uniform_location, @intCast(value.x), @intCast(value.y), @intCast(value.z), @intCast(value.w));
                } else {
                    return Error.InvalidValue;
                }
            },
            .boolean => {
                c.glUniform1i(uniform_location, if (value) 1 else 0);
            },
            .bvec2 => {
                if (value_type_info == .array) {
                    c.glUniform2i(uniform_location, if (value[0]) 1 else 0, if (value[1]) 1 else 0);
                } else if (value_type_info == .vector) {
                    c.glUniform2i(uniform_location, if (value.x) 1 else 0, if (value.y) 1 else 0);
                } else {
                    return Error.InvalidValue;
                }
            },
            .bvec3 => {
                if (value_type_info == .array) {
                    c.glUniform3i(uniform_location, if (value[0]) 1 else 0, if (value[1]) 1 else 0, if (value[2]) 1 else 0);
                } else if (value_type_info == .vector) {
                    c.glUniform3i(uniform_location, if (value.x) 1 else 0, if (value.y) 1 else 0, if (value.z) 1 else 0);
                } else {
                    return Error.InvalidValue;
                }
            },
            .bvec4 => {
                if (value_type_info == .array) {
                    c.glUniform4i(uniform_location, if (value[0]) 1 else 0, if (value[1]) 1 else 0, if (value[2]) 1 else 0, if (value[3]) 1 else 0);
                } else if (value_type_info == .vector) {
                    c.glUniform4i(uniform_location, if (value.x) 1 else 0, if (value.y) 1 else 0, if (value.z) 1 else 0, if (value.w) 1 else 0);
                } else {
                    return Error.InvalidValue;
                }
            },
            .mat2, .mat3, .mat4, .mat2x3, .mat2x4, .mat3x2, .mat3x4, .mat4x2, .mat4x3, .dmat2, .dmat3, .dmat4, .dmat2x3, .dmat2x4, .dmat3x2, .dmat3x4, .dmat4x2, .dmat4x3 => {
                const num_elements = switch (value_shader_type) {
                    .mat2, .dmat2 => 4,
                    .mat3, .dmat3 => 9,
                    .mat4, .dmat4 => 16,
                    .mat2x3, .dmat2x3, .mat3x2, .dmat3x2 => 6,
                    .mat2x4, .dmat2x4, .mat4x2, .dmat4x2 => 8,
                    .mat3x4, .dmat3x4, .mat4x3, .dmat4x3 => 12,
                    else => unreachable,
                };
                const MatValue = switch (value_shader_type) {
                    .mat2, .mat3, .mat4, .mat2x3, .mat2x4, .mat3x2, .mat3x4, .mat4x2, .mat4x3 => f32,
                    .dmat2, .dmat3, .dmat4, .dmat2x3, .dmat2x4, .dmat3x2, .dmat3x4, .dmat4x2, .dmat4x3 => f64,
                    else => unreachable,
                };

                var flat_values: [num_elements]MatValue = undefined;
                inline for (value, 0..) |row, i| {
                    const Row = @TypeOf(row);
                    const row_type_info = @typeInfo(Row);

                    const array_row: [row_type_info.vector.len]MatValue = row;
                    inline for (array_row, 0..) |v, j| {
                        flat_values[i * array_row.len + j] = v;
                    }
                }

                switch (value_shader_type) {
                    .mat2 => c.glUniformMatrix2fv(uniform_location, 1, c.GL_FALSE, &flat_values),
                    .mat3 => c.glUniformMatrix3fv(uniform_location, 1, c.GL_FALSE, &flat_values),
                    .mat4 => c.glUniformMatrix4fv(uniform_location, 1, c.GL_FALSE, &flat_values),
                    .mat2x3 => c.glUniformMatrix2x3fv(uniform_location, 1, c.GL_FALSE, &flat_values),
                    .mat2x4 => c.glUniformMatrix2x4fv(uniform_location, 1, c.GL_FALSE, &flat_values),
                    .mat3x2 => c.glUniformMatrix3x2fv(uniform_location, 1, c.GL_FALSE, &flat_values),
                    .mat3x4 => c.glUniformMatrix3x4fv(uniform_location, 1, c.GL_FALSE, &flat_values),
                    .mat4x2 => c.glUniformMatrix4x2fv(uniform_location, 1, c.GL_FALSE, &flat_values),
                    .mat4x3 => c.glUniformMatrix4x3fv(uniform_location, 1, c.GL_FALSE, &flat_values),
                    .dmat2 => c.glUniformMatrix2dv(uniform_location, 1, c.GL_FALSE, &flat_values),
                    .dmat3 => c.glUniformMatrix3dv(uniform_location, 1, c.GL_FALSE, &flat_values),
                    .dmat4 => c.glUniformMatrix4dv(uniform_location, 1, c.GL_FALSE, &flat_values),
                    .dmat2x3 => c.glUniformMatrix2x3dv(uniform_location, 1, c.GL_FALSE, &flat_values),
                    .dmat2x4 => c.glUniformMatrix2x4dv(uniform_location, 1, c.GL_FALSE, &flat_values),
                    .dmat3x2 => c.glUniformMatrix3x2dv(uniform_location, 1, c.GL_FALSE, &flat_values),
                    .dmat3x4 => c.glUniformMatrix3x4dv(uniform_location, 1, c.GL_FALSE, &flat_values),
                    .dmat4x2 => c.glUniformMatrix4x2dv(uniform_location, 1, c.GL_FALSE, &flat_values),
                    .dmat4x3 => c.glUniformMatrix4x3dv(uniform_location, 1, c.GL_FALSE, &flat_values),
                    else => unreachable,
                }
            },

            // Samplers
            .sampler1D, .sampler2D, .sampler3D, .samplerCube, .sampler1DShadow, .sampler2DShadow, .sampler1DArray, .sampler2DArray, .sampler1DArrayShadow, .sampler2DArrayShadow, .sampler2DMS, .sampler2DMSArray, .samplerCubeShadow, .samplerBuffer, .sampler2DRect, .sampler2DRectShadow, .isampler1D, .isampler2D, .isampler3D, .isamplerCube, .isampler1DArray, .isampler2DArray, .isampler2DMS, .isampler2DMSArray, .isamplerBuffer, .isampler2DRect, .usampler1D, .usampler2D, .usampler3D, .usamplerCube, .usampler1DArray, .usampler2DArray, .usampler2DMS, .usampler2DMSArray, .usamplerBuffer, .usampler2DRect => {
                c.glUniform1i(uniform_location, @intCast(value));
            },

            // Images
            .image1D, .image2D, .image3D, .image2DRect, .imageCube, .imageBuffer, .image1DArray, .image2DArray, .image2DMS, .image2DMSArray, .iimage1D, .iimage2D, .iimage3D, .iimage2DRect, .iimageCube, .iimageBuffer, .iimage1DArray, .iimage2DArray, .iimage2DMS, .iimage2DMSArray, .uimage1D, .uimage2D, .uimage3D, .uimage2DRect, .uimageCube, .uimageBuffer, .uimage1DArray, .uimage2DArray, .uimage2DMS, .uimage2DMSArray => {
                c.glUniform1i(uniform_location, @intCast(value));
            },

            .atomic_uint => {
                c.glUniform1ui(uniform_location, @intCast(value));
            },
            else => {
                @compileError("Unsupported type for uniform " ++ @typeName(Value));
            },
        }
    }

    pub fn use(self: *Self) void {
        c.glUseProgram(self.id);
    }

    pub fn link(self: *Self) Error!void {
        c.glLinkProgram(self.id);

        var program_linking_succeeded: c_int = undefined;
        c.glGetProgramiv(self.id, c.GL_LINK_STATUS, &program_linking_succeeded);
        if (program_linking_succeeded != 0) {
            return;
        }
        return Error.ShaderProgramLinking;
    }
};
