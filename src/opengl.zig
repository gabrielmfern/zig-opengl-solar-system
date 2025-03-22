const std = @import("std");
const c = @import("c.zig").c;

pub const Error = error{ ShaderCompilation, ShaderProgramLinking, UniformLocatioNotFound, InvalidTypeForUniform } || std.mem.Allocator.Error;

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

pub const VertexArray = struct {};

pub const ArrayBuffer = struct {
    id: c_uint,
    type: Type,

    pub const Type = enum(c_uint) {
        vertex_attributes = c.GL_ARRAY_BUFFER,
        atomic_counter = c.GL_ATOMIC_COUNTER_BUFFER,
        copy_source = c.GL_COPY_READ_BUFFER,
        copy_destination = c.GL_COPY_WRITE_BUFFER,
        indirect_dispatch = c.GL_DISPATCH_INDIRECT_BUFFER,
        indirect_draw = c.GL_DRAW_INDIRECT_BUFFER,
        vertex_indices = c.GL_ELEMENT_ARRAY_BUFFER,
        pixel_read_target = c.GL_PIXEL_PACK_BUFFER,
        texture_source = c.GL_PIXEL_UNPACK_BUFFER,
        query_result = c.GL_QUERY_BUFFER,
        shader_storage = c.GL_SHADER_STORAGE_BUFFER,
        texture = c.GL_TEXTURE_BUFFER,
        transform_feedback = c.GL_TRANSFORM_FEEDBACK_BUFFER,
        uniform_storage = c.GL_UNIFORM_BUFFER,
    };

    const Self = @This();

    pub fn init() ArrayBuffer {
        const self = ArrayBuffer{ .id = undefined };
        c.glGenBuffers(1, &self.id);
        return self;
    }

    pub fn from(vertices: [*]f32, vec_size: c_int, layout_index: c_uint) void {
        std.debug.assert(vec_size <= 4);
        std.debug.assert(vec_size >= 1);
        const self = Self.init();
        c.glBindBuffer(c.GL_ARRAY_BUFFER, self.id);
        c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), @ptrCast(@alignCast(&vertices)), c.GL_STATIC);
        c.glVertexAttribPointer(layout_index, vec_size, c.GL_FLOAT, c.GL_FALSE, 0, null);
        c.glEnableVertexAttribArray(layout_index);
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

    pub const UniformType = enum(c_int) {
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
    };

    pub fn getUniformType(self: *Self, location: c_uint) UniformType {
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
        const type_info = @typeInfo(Value);

        switch (type_info) {
            .float => |float| {
                if (float.bits == 32) {
                    if (uniform_type != .float) {
                        std.log.err("The uniform is of type {} while you passed in float", .{uniform_type});
                        return Error.InvalidTypeForUniform;
                    }
                    c.glUniform1f(uniform_location, value);
                } else {
                    if (uniform_type != .double) {
                        std.log.err("The uniform is of type {} while you passed in double", .{uniform_type});
                        return Error.InvalidTypeForUniform;
                    }
                    c.glUniform1d(uniform_location, value);
                }
            },
            .comptime_float => {
                if (uniform_type != .float) {
                    std.log.err("The uniform is of type {} while you passed in float", .{uniform_type});
                    return Error.InvalidTypeForUniform;
                }
                c.glUniform1f(uniform_location, value);
            },
            .@"struct" => |Struct| {
                if (Struct.is_tuple) {
                    std.debug.assert(Struct.fields.len > 0);
                    const FieldType = Struct.fields[0].type;
                    inline for (Struct.fields) |field| {
                        std.debug.assert(field.type == FieldType);
                    }
                    switch (FieldType) {
                        f32, comptime_float => {
                            switch (Struct.fields.len) {
                                1 => {
                                    if (uniform_type != .float) {
                                        std.log.err("The uniform is of type {} while you passed in float", .{uniform_type});
                                        return Error.InvalidTypeForUniform;
                                    }
                                    c.glUniform1f(uniform_location, value[0]);
                                },
                                2 => {
                                    if (uniform_type != .vec2) {
                                        std.log.err("The uniform is of type {} while you passed in vec2", .{uniform_type});
                                        return Error.InvalidTypeForUniform;
                                    }
                                    c.glUniform2f(uniform_location, value[0], value[1]);
                                },
                                3 => {
                                    if (uniform_type != .vec3) {
                                        std.log.err("The uniform is of type {} while you passed in vec3", .{uniform_type});
                                        return Error.InvalidTypeForUniform;
                                    }
                                    c.glUniform3f(uniform_location, value[0], value[1], value[2]);
                                },
                                4 => {
                                    if (uniform_type != .vec4) {
                                        std.log.err("The uniform is of type {} while you passed in vec4", .{uniform_type});
                                        return Error.InvalidTypeForUniform;
                                    }
                                    c.glUniform4f(uniform_location, value[0], value[1], value[2], value[3]);
                                },
                                else => {
                                    @compileError("Cannot store vectors larger than 4 components, but received tuple " ++ @typeName(Value));
                                },
                            }
                        },
                        else => {
                            @compileError("Unsupported vector component type " ++ @typeName(FieldType));
                        },
                    }
                } else {
                    @compileError("Struct for a uniform must be a tuple, found " ++ @typeName(Value));
                }
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
