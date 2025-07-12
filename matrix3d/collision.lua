-- 3MatrixLua Collision Detection Module

local M = {}

-- 2D AABB (Axis-Aligned Bounding Box) collision
function M.checkAABB2D(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
           x1 + w1 > x2 and
           y1 < y2 + h2 and
           y1 + h1 > y2
end

-- 3D AABB collision
function M.checkAABB3D(x1, y1, z1, w1, h1, d1, x2, y2, z2, w2, h2, d2)
    return x1 < x2 + w2 and x1 + w1 > x2 and
           y1 < y2 + h2 and y1 + h1 > y2 and
           z1 < z2 + d2 and z1 + d1 > z2
end

-- 2D Circle collision
function M.checkCircle2D(x1, y1, r1, x2, y2, r2)
    local dx = x2 - x1
    local dy = y2 - y1
    local distance = math.sqrt(dx * dx + dy * dy)
    return distance < (r1 + r2)
end

-- 3D Sphere collision
function M.checkSphere3D(x1, y1, z1, r1, x2, y2, z2, r2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
    return distance < (r1 + r2)
end

-- Point in 2D box
function M.pointInBox2D(px, py, bx, by, bw, bh)
    return px >= bx and px <= bx + bw and
           py >= by and py <= by + bh
end

-- Point in 3D box
function M.pointInBox3D(px, py, pz, bx, by, bz, bw, bh, bd)
    return px >= bx and px <= bx + bw and
           py >= by and py <= by + bh and
           pz >= bz and pz <= bz + bd
end

-- Ray-Box intersection (3D)
function M.rayBoxIntersection(rayOrigin, rayDir, boxMin, boxMax)
    local t1 = (boxMin.x - rayOrigin.x) / rayDir.x
    local t2 = (boxMax.x - rayOrigin.x) / rayDir.x
    local t3 = (boxMin.y - rayOrigin.y) / rayDir.y
    local t4 = (boxMax.y - rayOrigin.y) / rayDir.y
    local t5 = (boxMin.z - rayOrigin.z) / rayDir.z
    local t6 = (boxMax.z - rayOrigin.z) / rayDir.z
    
    local tmin = math.max(math.min(t1, t2), math.min(t3, t4), math.min(t5, t6))
    local tmax = math.min(math.max(t1, t2), math.max(t3, t4), math.max(t5, t6))
    
    return tmax >= 0 and tmax >= tmin, tmin
end

-- Collision response for AABB (pushes obj1 out of obj2)
function M.resolveAABB3D(x1, y1, z1, w1, h1, d1, vx1, vy1, vz1,
                         x2, y2, z2, w2, h2, d2)
    -- Calculate overlap on each axis
    local overlapX = (w1 + w2) / 2 - math.abs(x1 - x2)
    local overlapY = (h1 + h2) / 2 - math.abs(y1 - y2)
    local overlapZ = (d1 + d2) / 2 - math.abs(z1 - z2)
    
    -- Find smallest overlap (axis of least penetration)
    local minOverlap = math.min(overlapX, overlapY, overlapZ)
    
    local newX, newY, newZ = x1, y1, z1
    local newVX, newVY, newVZ = vx1, vy1, vz1
    local normal = {x = 0, y = 0, z = 0}
    
    if minOverlap == overlapX then
        -- Push out on X axis
        if x1 < x2 then
            newX = x2 - (w1 + w2) / 2
            normal.x = -1
        else
            newX = x2 + (w1 + w2) / 2
            normal.x = 1
        end
        newVX = 0
    elseif minOverlap == overlapY then
        -- Push out on Y axis
        if y1 < y2 then
            newY = y2 - (h1 + h2) / 2
            normal.y = -1
        else
            newY = y2 + (h1 + h2) / 2
            normal.y = 1
        end
        newVY = 0
    else
        -- Push out on Z axis
        if z1 < z2 then
            newZ = z2 - (d1 + d2) / 2
            normal.z = -1
        else
            newZ = z2 + (d1 + d2) / 2
            normal.z = 1
        end
        newVZ = 0
    end
    
    return newX, newY, newZ, newVX, newVY, newVZ, normal
end

-- Collision Box class for easier management
local CollisionBox = {}
CollisionBox.__index = CollisionBox

function CollisionBox.new(x, y, z, width, height, depth)
    return setmetatable({
        x = x or 0,
        y = y or 0,
        z = z or 0,
        width = width or 1,
        height = height or 1,
        depth = depth or 1
    }, CollisionBox)
end

function CollisionBox:center()
    return self.x + self.width/2, self.y + self.height/2, self.z + self.depth/2
end

function CollisionBox:setCenter(x, y, z)
    self.x = x - self.width/2
    self.y = y - self.height/2
    self.z = z - self.depth/2
end

function CollisionBox:intersects(other)
    return M.checkAABB3D(
        self.x, self.y, self.z, self.width, self.height, self.depth,
        other.x, other.y, other.z, other.width, other.height, other.depth
    )
end

function CollisionBox:contains(x, y, z)
    return M.pointInBox3D(x, y, z, self.x, self.y, self.z, 
                         self.width, self.height, self.depth)
end

M.Box = CollisionBox

-- Collision Sphere class
local CollisionSphere = {}
CollisionSphere.__index = CollisionSphere

function CollisionSphere.new(x, y, z, radius)
    return setmetatable({
        x = x or 0,
        y = y or 0,
        z = z or 0,
        radius = radius or 1
    }, CollisionSphere)
end

function CollisionSphere:intersects(other)
    if other.radius then
        -- Sphere-sphere collision
        return M.checkSphere3D(
            self.x, self.y, self.z, self.radius,
            other.x, other.y, other.z, other.radius
        )
    else
        -- Sphere-box collision (simplified)
        local cx, cy, cz = other:center()
        return M.checkSphere3D(
            self.x, self.y, self.z, self.radius,
            cx, cy, cz, math.min(other.width, other.height, other.depth) / 2
        )
    end
end

M.Sphere = CollisionSphere

-- Convenience functions for centered boxes
function M.checkCenteredAABB3D(x1, y1, z1, w1, h1, d1, x2, y2, z2, w2, h2, d2)
    return M.checkAABB3D(
        x1 - w1/2, y1 - h1/2, z1 - d1/2, w1, h1, d1,
        x2 - w2/2, y2 - h2/2, z2 - d2/2, w2, h2, d2
    )
end

function M.checkCenteredAABB2D(x1, y1, w1, h1, x2, y2, w2, h2)
    return M.checkAABB2D(
        x1 - w1/2, y1 - h1/2, w1, h1,
        x2 - w2/2, y2 - h2/2, w2, h2
    )
end

return M