local ffi = require("ffi")

local gl
if ffi.os == "OSX" then
    gl = ffi.load("/System/Library/Frameworks/OpenGL.framework/OpenGL")
else
    gl = ffi.load("GL")
end

-- Constants
local GL_ARRAY_BUFFER = 0x8892
local GL_ELEMENT_ARRAY_BUFFER = 0x8893
local GL_STATIC_DRAW = 0x88E4
local GL_FLOAT = 0x1406
local GL_UNSIGNED_INT = 0x1405
local GL_FALSE = 0
local GL_TRIANGLES = 0x0004

local Mesh = {}
Mesh.__index = Mesh

function Mesh.new(vertices, indices, attributes)
    local self = setmetatable({}, Mesh)
    
    -- Generate buffers
    self.vao = ffi.new("unsigned int[1]")
    self.vbo = ffi.new("unsigned int[1]")
    self.ebo = ffi.new("unsigned int[1]")
    
    gl.glGenVertexArrays(1, self.vao)
    gl.glGenBuffers(1, self.vbo)
    gl.glGenBuffers(1, self.ebo)
    
    -- Bind VAO
    gl.glBindVertexArray(self.vao[0])
    
    -- Upload vertex data
    gl.glBindBuffer(GL_ARRAY_BUFFER, self.vbo[0])
    local vertexData = ffi.new("float[?]", #vertices, vertices)
    gl.glBufferData(GL_ARRAY_BUFFER, ffi.sizeof(vertexData), vertexData, GL_STATIC_DRAW)
    
    -- Upload index data if provided
    if indices then
        gl.glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.ebo[0])
        local indexData = ffi.new("unsigned int[?]", #indices, indices)
        gl.glBufferData(GL_ELEMENT_ARRAY_BUFFER, ffi.sizeof(indexData), indexData, GL_STATIC_DRAW)
        self.indexCount = #indices
    end
    
    -- Set attributes
    local stride = 0
    for _, attr in ipairs(attributes) do
        stride = stride + attr.size * ffi.sizeof("float")
    end
    
    local offset = 0
    for i, attr in ipairs(attributes) do
        local location = i - 1  -- Attribute locations start at 0
        gl.glEnableVertexAttribArray(location)
        gl.glVertexAttribPointer(location, attr.size, GL_FLOAT, GL_FALSE, stride, ffi.cast("void*", offset))
        offset = offset + attr.size * ffi.sizeof("float")
    end
    
    -- Unbind
    gl.glBindVertexArray(0)
    
    self.vertexCount = #vertices / (stride / ffi.sizeof("float"))
    
    return self
end

function Mesh:draw()
    gl.glBindVertexArray(self.vao[0])
    
    if self.indexCount then
        gl.glDrawElements(GL_TRIANGLES, self.indexCount, GL_UNSIGNED_INT, nil)
    else
        gl.glDrawArrays(GL_TRIANGLES, 0, self.vertexCount)
    end
    
    gl.glBindVertexArray(0)
end

-- Primitive shapes
function Mesh.triangle()
    local vertices = {
        -- positions      colors
        -0.5, -0.5, 0.0,  1.0, 0.0, 0.0,
         0.5, -0.5, 0.0,  0.0, 1.0, 0.0,
         0.0,  0.5, 0.0,  0.0, 0.0, 1.0
    }
    
    return Mesh.new(vertices, nil, {
        {size = 3}, -- position
        {size = 3}  -- color
    })
end

function Mesh.quad(width, height)
    width = width or 1
    height = height or 1
    
    local hw = width / 2
    local hh = height / 2
    
    local vertices = {
        -- positions     tex coords
        -hw, -hh, 0.0,   0.0, 0.0,
         hw, -hh, 0.0,   1.0, 0.0,
         hw,  hh, 0.0,   1.0, 1.0,
        -hw,  hh, 0.0,   0.0, 1.0
    }
    
    local indices = {
        0, 1, 2,
        2, 3, 0
    }
    
    return Mesh.new(vertices, indices, {
        {size = 3}, -- position
        {size = 2}  -- texcoord
    })
end

function Mesh.cube(size)
    size = size or 1
    local s = size / 2
    
    local vertices = {
        -- Front face
        -s, -s,  s,  0, 0, 1,  0, 0,
         s, -s,  s,  0, 0, 1,  1, 0,
         s,  s,  s,  0, 0, 1,  1, 1,
        -s,  s,  s,  0, 0, 1,  0, 1,
        -- Back face
        -s, -s, -s,  0, 0, -1,  1, 0,
         s, -s, -s,  0, 0, -1,  0, 0,
         s,  s, -s,  0, 0, -1,  0, 1,
        -s,  s, -s,  0, 0, -1,  1, 1,
        -- Top face
        -s,  s, -s,  0, 1, 0,  0, 1,
         s,  s, -s,  0, 1, 0,  1, 1,
         s,  s,  s,  0, 1, 0,  1, 0,
        -s,  s,  s,  0, 1, 0,  0, 0,
        -- Bottom face
        -s, -s, -s,  0, -1, 0,  0, 0,
         s, -s, -s,  0, -1, 0,  1, 0,
         s, -s,  s,  0, -1, 0,  1, 1,
        -s, -s,  s,  0, -1, 0,  0, 1,
        -- Right face
         s, -s, -s,  1, 0, 0,  1, 0,
         s,  s, -s,  1, 0, 0,  1, 1,
         s,  s,  s,  1, 0, 0,  0, 1,
         s, -s,  s,  1, 0, 0,  0, 0,
        -- Left face
        -s, -s, -s,  -1, 0, 0,  0, 0,
        -s,  s, -s,  -1, 0, 0,  0, 1,
        -s,  s,  s,  -1, 0, 0,  1, 1,
        -s, -s,  s,  -1, 0, 0,  1, 0
    }
    
    local indices = {}
    for i = 0, 5 do
        local base = i * 4
        table.insert(indices, base + 0)
        table.insert(indices, base + 1)
        table.insert(indices, base + 2)
        table.insert(indices, base + 2)
        table.insert(indices, base + 3)
        table.insert(indices, base + 0)
    end
    
    return Mesh.new(vertices, indices, {
        {size = 3}, -- position
        {size = 3}, -- normal
        {size = 2}  -- texcoord
    })
end

return Mesh