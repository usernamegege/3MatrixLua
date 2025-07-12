package.path = package.path .. ";./?.lua;./?/init.lua"

local m3d = require("matrix3d")

-- Create window
local window = m3d.createWindow(800, 600, "3MatrixLua - 2D Triangle")

-- Create shader
local shader = m3d.Shader.new(m3d.Shader.default2D.vertex, m3d.Shader.default2D.fragment)

-- Create triangle mesh
local triangle = m3d.Mesh.triangle()

-- Setup 2D projection (orthographic)
local projection = m3d.Matrix4.ortho(-1, 1, -1, 1, -1, 1)

-- Main loop
while not window:shouldClose() do
    -- Clear
    window:clear(0.1, 0.1, 0.2, 1.0)
    
    -- Use shader
    shader:use()
    
    -- Set projection
    shader:setMat4("projection", projection)
    
    -- Draw triangle
    triangle:draw()
    
    -- Swap and poll
    window:swapBuffers()
    m3d.pollEvents()
end

-- Cleanup
window:destroy()
m3d.terminate()