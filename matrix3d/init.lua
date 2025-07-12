local ok, ffi = pcall(require, "ffi")
if not ok then
    error([[
3MatrixLua requires LuaJIT for FFI support.
Please install LuaJIT: https://luajit.org/

On macOS with Homebrew: brew install luajit
On Ubuntu/Debian: sudo apt-get install luajit
On Windows: Download from https://luajit.org/download.html
]])
end

-- GLFW constants
ffi.cdef[[
    // Window
    typedef struct GLFWwindow GLFWwindow;
    typedef struct GLFWmonitor GLFWmonitor;
    
    // GLFW functions
    int glfwInit();
    void glfwTerminate();
    GLFWwindow* glfwCreateWindow(int width, int height, const char* title, GLFWmonitor* monitor, GLFWwindow* share);
    void glfwDestroyWindow(GLFWwindow* window);
    int glfwWindowShouldClose(GLFWwindow* window);
    void glfwSwapBuffers(GLFWwindow* window);
    void glfwPollEvents();
    void glfwMakeContextCurrent(GLFWwindow* window);
    void glfwWindowHint(int hint, int value);
    void glfwGetFramebufferSize(GLFWwindow* window, int* width, int* height);
    void glfwSwapInterval(int interval);
    
    // OpenGL functions
    void glClearColor(float red, float green, float blue, float alpha);
    void glClear(unsigned int mask);
    void glViewport(int x, int y, int width, int height);
    void glEnable(unsigned int cap);
    
    // Shaders
    unsigned int glCreateShader(unsigned int type);
    void glShaderSource(unsigned int shader, int count, const char** string, const int* length);
    void glCompileShader(unsigned int shader);
    void glGetShaderiv(unsigned int shader, unsigned int pname, int* params);
    void glGetShaderInfoLog(unsigned int shader, int bufSize, int* length, char* infoLog);
    unsigned int glCreateProgram();
    void glAttachShader(unsigned int program, unsigned int shader);
    void glLinkProgram(unsigned int program);
    void glGetProgramiv(unsigned int program, unsigned int pname, int* params);
    void glGetProgramInfoLog(unsigned int program, int bufSize, int* length, char* infoLog);
    void glUseProgram(unsigned int program);
    void glDeleteShader(unsigned int shader);
    
    // Buffers
    void glGenBuffers(int n, unsigned int* buffers);
    void glBindBuffer(unsigned int target, unsigned int buffer);
    void glBufferData(unsigned int target, size_t size, const void* data, unsigned int usage);
    void glGenVertexArrays(int n, unsigned int* arrays);
    void glBindVertexArray(unsigned int array);
    void glEnableVertexAttribArray(unsigned int index);
    void glVertexAttribPointer(unsigned int index, int size, unsigned int type, unsigned char normalized, int stride, const void* pointer);
    
    // Drawing
    void glDrawArrays(unsigned int mode, int first, int count);
    void glDrawElements(unsigned int mode, int count, unsigned int type, const void* indices);
    
    // Uniforms
    int glGetUniformLocation(unsigned int program, const char* name);
    void glUniform1f(int location, float v0);
    void glUniform2f(int location, float v0, float v1);
    void glUniform3f(int location, float v0, float v1, float v2);
    void glUniform4f(int location, float v0, float v1, float v2, float v3);
    void glUniformMatrix4fv(int location, int count, unsigned char transpose, const float* value);
]]

-- Load libraries
local glfw = ffi.load("glfw")
local gl
if ffi.os == "OSX" then
    gl = ffi.load("/System/Library/Frameworks/OpenGL.framework/OpenGL")
else
    gl = ffi.load("GL")
end

-- Constants
local GLFW_CONTEXT_VERSION_MAJOR = 0x00022002
local GLFW_CONTEXT_VERSION_MINOR = 0x00022003
local GLFW_OPENGL_PROFILE = 0x00022008
local GLFW_OPENGL_CORE_PROFILE = 0x00032001
local GLFW_OPENGL_FORWARD_COMPAT = 0x00022006

local GL_COLOR_BUFFER_BIT = 0x00004000
local GL_DEPTH_BUFFER_BIT = 0x00000100
local GL_DEPTH_TEST = 0x0B71
local GL_VERTEX_SHADER = 0x8B31
local GL_FRAGMENT_SHADER = 0x8B30
local GL_COMPILE_STATUS = 0x8B81
local GL_LINK_STATUS = 0x8B82
local GL_ARRAY_BUFFER = 0x8892
local GL_ELEMENT_ARRAY_BUFFER = 0x8893
local GL_STATIC_DRAW = 0x88E4
local GL_TRIANGLES = 0x0004
local GL_FLOAT = 0x1406
local GL_UNSIGNED_INT = 0x1405
local GL_FALSE = 0
local GL_TRUE = 1

-- Framework table
local matrix3d = {}

-- Load submodules
matrix3d.math = require("matrix3d.math")
matrix3d.Shader = require("matrix3d.shader")
matrix3d.Mesh = require("matrix3d.mesh")
matrix3d.ObjLoader = require("matrix3d.obj_loader")

-- Initialize GLFW
local initialized = false
local function ensureInit()
    if not initialized then
        if glfw.glfwInit() == 0 then
            error("Failed to initialize GLFW")
        end
        initialized = true
    end
end

-- Window class
local Window = {}
Window.__index = Window

function Window.new(width, height, title)
    ensureInit()
    
    -- Set OpenGL version hints
    glfw.glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3)
    glfw.glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3)
    glfw.glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE)
    
    -- macOS specific
    if ffi.os == "OSX" then
        glfw.glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE)
    end
    
    -- Create window
    local handle = glfw.glfwCreateWindow(width, height, title, nil, nil)
    if handle == nil then
        error("Failed to create window")
    end
    
    -- Make context current
    glfw.glfwMakeContextCurrent(handle)
    
    -- Get actual framebuffer size (for retina displays)
    local fbWidth = ffi.new("int[1]")
    local fbHeight = ffi.new("int[1]")
    glfw.glfwGetFramebufferSize(handle, fbWidth, fbHeight)
    
    -- Set viewport to actual framebuffer size
    gl.glViewport(0, 0, fbWidth[0], fbHeight[0])
    gl.glEnable(GL_DEPTH_TEST)
    
    -- Enable v-sync
    glfw.glfwSwapInterval(1)
    
    local self = setmetatable({}, Window)
    self.handle = handle
    self.width = width
    self.height = height
    self.fbWidth = fbWidth[0]
    self.fbHeight = fbHeight[0]
    return self
end

function Window:shouldClose()
    return glfw.glfwWindowShouldClose(self.handle) ~= 0
end

function Window:swapBuffers()
    glfw.glfwSwapBuffers(self.handle)
end

function Window:clear(r, g, b, a)
    gl.glClearColor(r or 0, g or 0, b or 0, a or 1)
    gl.glClear(GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT)
end

function Window:destroy()
    glfw.glfwDestroyWindow(self.handle)
end

-- Module functions
function matrix3d.createWindow(width, height, title)
    return Window.new(width, height, title)
end

function matrix3d.pollEvents()
    glfw.glfwPollEvents()
end

function matrix3d.terminate()
    glfw.glfwTerminate()
    initialized = false
end

-- Convenience exports
matrix3d.vec2 = matrix3d.math.vec2
matrix3d.vec3 = matrix3d.math.vec3
matrix3d.mat4 = matrix3d.math.mat4
matrix3d.Vector2 = matrix3d.math.Vector2
matrix3d.Vector3 = matrix3d.math.Vector3
matrix3d.Matrix4 = matrix3d.math.Matrix4

-- OpenGL constants for users
matrix3d.GL = {
    TRIANGLES = GL_TRIANGLES,
    DEPTH_TEST = GL_DEPTH_TEST,
    COLOR_BUFFER_BIT = GL_COLOR_BUFFER_BIT,
    DEPTH_BUFFER_BIT = GL_DEPTH_BUFFER_BIT
}

return matrix3d