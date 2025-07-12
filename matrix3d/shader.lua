local ffi = require("ffi")

-- Get OpenGL functions from parent module
local gl
if ffi.os == "OSX" then
    gl = ffi.load("/System/Library/Frameworks/OpenGL.framework/OpenGL")
else
    gl = ffi.load("GL")
end

-- Constants
local GL_VERTEX_SHADER = 0x8B31
local GL_FRAGMENT_SHADER = 0x8B30
local GL_COMPILE_STATUS = 0x8B81
local GL_LINK_STATUS = 0x8B82

local Shader = {}
Shader.__index = Shader

local function compileShader(source, shaderType)
    local shader = gl.glCreateShader(shaderType)
    local src = ffi.new("const char*[1]", ffi.new("const char*", source))
    local len = ffi.new("int[1]", #source)
    
    gl.glShaderSource(shader, 1, src, len)
    gl.glCompileShader(shader)
    
    -- Check compilation
    local success = ffi.new("int[1]")
    gl.glGetShaderiv(shader, GL_COMPILE_STATUS, success)
    
    if success[0] == 0 then
        local infoLog = ffi.new("char[512]")
        gl.glGetShaderInfoLog(shader, 512, nil, infoLog)
        local shaderTypeStr = shaderType == GL_VERTEX_SHADER and "VERTEX" or "FRAGMENT"
        error(shaderTypeStr .. " shader compilation failed: " .. ffi.string(infoLog))
    end
    
    return shader
end

function Shader.new(vertexSource, fragmentSource)
    local self = setmetatable({}, Shader)
    
    -- Compile shaders
    local vertexShader = compileShader(vertexSource, GL_VERTEX_SHADER)
    local fragmentShader = compileShader(fragmentSource, GL_FRAGMENT_SHADER)
    
    -- Create program
    self.program = gl.glCreateProgram()
    gl.glAttachShader(self.program, vertexShader)
    gl.glAttachShader(self.program, fragmentShader)
    gl.glLinkProgram(self.program)
    
    -- Check linking
    local success = ffi.new("int[1]")
    gl.glGetProgramiv(self.program, GL_LINK_STATUS, success)
    
    if success[0] == 0 then
        local infoLog = ffi.new("char[512]")
        gl.glGetProgramInfoLog(self.program, 512, nil, infoLog)
        error("Shader program linking failed: " .. ffi.string(infoLog))
    end
    
    -- Clean up
    gl.glDeleteShader(vertexShader)
    gl.glDeleteShader(fragmentShader)
    
    self.uniforms = {}
    
    return self
end

function Shader:use()
    gl.glUseProgram(self.program)
end

function Shader:getUniformLocation(name)
    if not self.uniforms[name] then
        self.uniforms[name] = gl.glGetUniformLocation(self.program, name)
    end
    return self.uniforms[name]
end

function Shader:setFloat(name, value)
    gl.glUniform1f(self:getUniformLocation(name), value)
end

function Shader:setVec2(name, x, y)
    gl.glUniform2f(self:getUniformLocation(name), x, y)
end

function Shader:setVec3(name, x, y, z)
    gl.glUniform3f(self:getUniformLocation(name), x, y, z)
end

function Shader:setVec4(name, x, y, z, w)
    gl.glUniform4f(self:getUniformLocation(name), x, y, z, w)
end

function Shader:setMat4(name, matrix)
    local data = ffi.new("float[16]", matrix.data)
    gl.glUniformMatrix4fv(self:getUniformLocation(name), 1, 0, data)
end

-- Default shaders
Shader.default2D = {
    vertex = [[
#version 330 core
layout (location = 0) in vec2 aPos;
layout (location = 1) in vec4 aColor;

out vec4 vertexColor;

uniform mat4 projection;

void main() {
    gl_Position = projection * vec4(aPos, 0.0, 1.0);
    vertexColor = aColor;
}
]],
    fragment = [[
#version 330 core
in vec4 vertexColor;
out vec4 FragColor;

void main() {
    FragColor = vertexColor;
}
]]
}

Shader.default3D = {
    vertex = [[
#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aNormal;
layout (location = 2) in vec2 aTexCoord;

out vec3 FragPos;
out vec3 Normal;
out vec2 TexCoord;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main() {
    FragPos = vec3(model * vec4(aPos, 1.0));
    Normal = mat3(transpose(inverse(model))) * aNormal;
    TexCoord = aTexCoord;
    
    gl_Position = projection * view * vec4(FragPos, 1.0);
}
]],
    fragment = [[
#version 330 core
in vec3 FragPos;
in vec3 Normal;
in vec2 TexCoord;

out vec4 FragColor;

uniform vec3 lightPos;
uniform vec3 lightColor;
uniform vec3 objectColor;

void main() {
    // Ambient
    float ambientStrength = 0.1;
    vec3 ambient = ambientStrength * lightColor;
    
    // Diffuse
    vec3 norm = normalize(Normal);
    vec3 lightDir = normalize(lightPos - FragPos);
    float diff = max(dot(norm, lightDir), 0.0);
    vec3 diffuse = diff * lightColor;
    
    vec3 result = (ambient + diffuse) * objectColor;
    FragColor = vec4(result, 1.0);
}
]]
}

return Shader