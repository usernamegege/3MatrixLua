local math = require("math")
local M = {}

-- Vector2
local Vector2 = {}
Vector2.__index = Vector2

function Vector2.new(x, y)
    return setmetatable({x = x or 0, y = y or 0}, Vector2)
end

function Vector2:__add(other)
    return Vector2.new(self.x + other.x, self.y + other.y)
end

function Vector2:__sub(other)
    return Vector2.new(self.x - other.x, self.y - other.y)
end

function Vector2:__mul(scalar)
    return Vector2.new(self.x * scalar, self.y * scalar)
end

function Vector2:dot(other)
    return self.x * other.x + self.y * other.y
end

function Vector2:length()
    return math.sqrt(self.x * self.x + self.y * self.y)
end

function Vector2:normalize()
    local len = self:length()
    if len > 0 then
        return Vector2.new(self.x / len, self.y / len)
    end
    return Vector2.new(0, 0)
end

-- Vector3
local Vector3 = {}
Vector3.__index = Vector3

function Vector3.new(x, y, z)
    return setmetatable({x = x or 0, y = y or 0, z = z or 0}, Vector3)
end

function Vector3:__add(other)
    return Vector3.new(self.x + other.x, self.y + other.y, self.z + other.z)
end

function Vector3:__sub(other)
    return Vector3.new(self.x - other.x, self.y - other.y, self.z - other.z)
end

function Vector3:__mul(scalar)
    return Vector3.new(self.x * scalar, self.y * scalar, self.z * scalar)
end

function Vector3:cross(other)
    return Vector3.new(
        self.y * other.z - self.z * other.y,
        self.z * other.x - self.x * other.z,
        self.x * other.y - self.y * other.x
    )
end

function Vector3:dot(other)
    return self.x * other.x + self.y * other.y + self.z * other.z
end

function Vector3:length()
    return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
end

function Vector3:normalize()
    local len = self:length()
    if len > 0 then
        return Vector3.new(self.x / len, self.y / len, self.z / len)
    end
    return Vector3.new(0, 0, 0)
end

-- Matrix4
local Matrix4 = {}
Matrix4.__index = Matrix4

function Matrix4.new(data)
    local m = setmetatable({}, Matrix4)
    m.data = data or {
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    }
    return m
end

function Matrix4:__mul(other)
    local result = {}
    for i = 0, 3 do
        for j = 0, 3 do
            local sum = 0
            for k = 0, 3 do
                sum = sum + self.data[i * 4 + k + 1] * other.data[k * 4 + j + 1]
            end
            result[i * 4 + j + 1] = sum
        end
    end
    return Matrix4.new(result)
end

function Matrix4.identity()
    return Matrix4.new()
end

function Matrix4.translate(x, y, z)
    return Matrix4.new({
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        x, y, z, 1
    })
end

function Matrix4.scale(x, y, z)
    return Matrix4.new({
        x, 0, 0, 0,
        0, y, 0, 0,
        0, 0, z, 0,
        0, 0, 0, 1
    })
end

function Matrix4.rotateX(angle)
    local c = math.cos(angle)
    local s = math.sin(angle)
    return Matrix4.new({
        1, 0, 0, 0,
        0, c, -s, 0,
        0, s, c, 0,
        0, 0, 0, 1
    })
end

function Matrix4.rotateY(angle)
    local c = math.cos(angle)
    local s = math.sin(angle)
    return Matrix4.new({
        c, 0, s, 0,
        0, 1, 0, 0,
        -s, 0, c, 0,
        0, 0, 0, 1
    })
end

function Matrix4.rotateZ(angle)
    local c = math.cos(angle)
    local s = math.sin(angle)
    return Matrix4.new({
        c, -s, 0, 0,
        s, c, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    })
end

function Matrix4.perspective(fov, aspect, near, far)
    local f = 1 / math.tan(fov / 2)
    local nf = 1 / (near - far)
    
    return Matrix4.new({
        f / aspect, 0, 0, 0,
        0, f, 0, 0,
        0, 0, (far + near) * nf, -1,
        0, 0, 2 * far * near * nf, 0
    })
end

function Matrix4.ortho(left, right, bottom, top, near, far)
    local lr = 1 / (right - left)
    local bt = 1 / (top - bottom)
    local nf = 1 / (far - near)
    
    return Matrix4.new({
        2 * lr, 0, 0, 0,
        0, 2 * bt, 0, 0,
        0, 0, -2 * nf, 0,
        -(right + left) * lr, -(top + bottom) * bt, -(far + near) * nf, 1
    })
end

function Matrix4.lookAt(eye, target, up)
    local z = (eye - target):normalize()
    local x = up:cross(z):normalize()
    local y = z:cross(x)
    
    return Matrix4.new({
        x.x, y.x, z.x, 0,
        x.y, y.y, z.y, 0,
        x.z, y.z, z.z, 0,
        -x:dot(eye), -y:dot(eye), -z:dot(eye), 1
    })
end

M.Vector2 = Vector2
M.Vector3 = Vector3
M.Matrix4 = Matrix4
M.vec2 = Vector2.new
M.vec3 = Vector3.new
M.mat4 = Matrix4.new

return M