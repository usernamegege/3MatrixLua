-- Add the parent directory to the path so we can require matrix3d
package.path = package.path .. ";./?.lua;./?/init.lua"

local m3d = require("matrix3d")

-- Create window
local window = m3d.createWindow(800, 600, "3MatrixLua - Pure Lua!")

-- Main loop
while not window:shouldClose() do
    -- Clear screen with dark blue color
    window:clear(0.1, 0.1, 0.2, 1.0)
    
    -- Swap buffers
    window:swapBuffers()
    
    -- Poll for events
    m3d.pollEvents()
end

-- Clean up
window:destroy()
m3d.terminate()

print("Window closed!")