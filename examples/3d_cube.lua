package.path = package.path .. ";./?.lua;./?/init.lua"

local m3d = require("matrix3d")

-- Create window
local window = m3d.createWindow(800, 600, "3MatrixLua - 3D Cube")

-- Create shader
local shader = m3d.Shader.new(m3d.Shader.default3D.vertex, m3d.Shader.default3D.fragment)

-- Create cube mesh
local cube = m3d.Mesh.cube(1.0)

-- Setup matrices
local projection = m3d.Matrix4.perspective(math.rad(45), window.fbWidth/window.fbHeight, 0.1, 100.0)
local view = m3d.Matrix4.lookAt(
    m3d.vec3(3, 3, 3),  -- eye
    m3d.vec3(0, 0, 0),  -- target
    m3d.vec3(0, 1, 0)   -- up
)

local rotation = 0

-- Main loop
while not window:shouldClose() do
    -- Clear
    window:clear(0.1, 0.1, 0.2, 1.0)
    
    -- Use shader
    shader:use()
    
    -- Update rotation
    rotation = rotation + 0.01
    local model = m3d.Matrix4.rotateY(rotation)
    
    -- Set uniforms
    shader:setMat4("model", model)
    shader:setMat4("view", view)
    shader:setMat4("projection", projection)
    shader:setVec3("lightPos", 5, 5, 5)
    shader:setVec3("lightColor", 1, 1, 1)
    shader:setVec3("objectColor", 1, 0.5, 0.31)
    
    -- Draw cube
    cube:draw()
    
    -- Swap and poll
    window:swapBuffers()
    m3d.pollEvents()
end

-- Cleanup
window:destroy()
m3d.terminate()