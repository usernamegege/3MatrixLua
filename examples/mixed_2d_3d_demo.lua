package.path = package.path .. ";../?.lua;../?/init.lua"

local m3d = require("matrix3d")

-- Create window
local window = m3d.createWindow(1024, 768, "3MatrixLua - 2D UI + 3D Scene")

-- Shaders
local shader3D = m3d.Shader.new(m3d.Shader.default3D.vertex, m3d.Shader.default3D.fragment)
local shader2D = m3d.Shader.new(m3d.Shader.default2D.vertex, m3d.Shader.default2D.fragment)

-- Meshes
local cube = m3d.Mesh.cube(1.0)
local quad = m3d.Mesh.quad(1.0, 1.0)

-- 3D scene setup
local projection3D = m3d.Matrix4.perspective(math.rad(45), 1024/768, 0.1, 100)
local view = m3d.Matrix4.lookAt(m3d.vec3(3, 3, 3), m3d.vec3(0, 0, 0), m3d.vec3(0, 1, 0))

-- 2D UI setup
local projection2D = m3d.Matrix4.ortho(0, 1024, 768, 0, -1, 1)

-- Create UI elements (health bar, score, etc.)
local uiElements = {
    healthBar = {
        x = 20, y = 20, 
        width = 200, height = 30,
        value = 1.0,  -- 0 to 1
        color = m3d.vec3(0, 1, 0)
    },
    energyBar = {
        x = 20, y = 60,
        width = 200, height = 20,
        value = 0.7,
        color = m3d.vec3(0, 0.5, 1)
    },
    minimap = {
        x = 1024 - 220, y = 20,
        width = 200, height = 200
    }
}

-- Game objects
local objects = {}
for i = 1, 8 do
    local angle = (i - 1) * math.pi * 2 / 8
    table.insert(objects, {
        pos = m3d.vec3(math.cos(angle) * 2, 0, math.sin(angle) * 2),
        color = m3d.vec3(math.random(), math.random(), math.random()),
        scale = math.random() * 0.5 + 0.5
    })
end

local time = 0

-- Helper function to draw 2D rectangle
local function drawRect(x, y, width, height, r, g, b, a)
    local model = m3d.Matrix4.translate(x + width/2, y + height/2, 0) *
                  m3d.Matrix4.scale(width, height, 1)
    shader2D:setMat4("projection", projection2D * model)
    -- Note: Using quad mesh, color comes from vertex colors
    quad:draw()
end

-- Main loop
while not window:shouldClose() do
    time = time + 0.016
    
    -- Update UI values
    uiElements.healthBar.value = math.abs(math.sin(time)) 
    uiElements.energyBar.value = math.abs(math.cos(time * 1.5))
    
    -- Update health bar color based on value
    if uiElements.healthBar.value > 0.6 then
        uiElements.healthBar.color = m3d.vec3(0, 1, 0)  -- green
    elseif uiElements.healthBar.value > 0.3 then
        uiElements.healthBar.color = m3d.vec3(1, 1, 0)  -- yellow
    else
        uiElements.healthBar.color = m3d.vec3(1, 0, 0)  -- red
    end
    
    -- Clear screen
    window:clear(0.1, 0.1, 0.15, 1.0)
    
    -- === Render 3D Scene ===
    shader3D:use()
    shader3D:setMat4("view", view)
    shader3D:setMat4("projection", projection3D)
    shader3D:setVec3("lightPos", 5, 5, 5)
    shader3D:setVec3("lightColor", 1, 1, 1)
    
    -- Central rotating cube
    local centerModel = m3d.Matrix4.rotateY(time) * m3d.Matrix4.rotateX(time * 0.7)
    shader3D:setMat4("model", centerModel)
    shader3D:setVec3("objectColor", 0.8, 0.2, 0.2)
    cube:draw()
    
    -- Orbiting cubes
    for i, obj in ipairs(objects) do
        local orbitRadius = 2 + math.sin(time + i) * 0.5
        local angle = time + (i - 1) * math.pi * 2 / #objects
        
        obj.pos.x = math.cos(angle) * orbitRadius
        obj.pos.z = math.sin(angle) * orbitRadius
        obj.pos.y = math.sin(time * 2 + i) * 0.5
        
        local model = m3d.Matrix4.translate(obj.pos.x, obj.pos.y, obj.pos.z) *
                     m3d.Matrix4.scale(obj.scale, obj.scale, obj.scale)
        
        shader3D:setMat4("model", model)
        shader3D:setVec3("objectColor", obj.color.x, obj.color.y, obj.color.z)
        cube:draw()
    end
    
    -- === Render 2D UI ===
    shader2D:use()
    
    -- Draw UI background panels
    -- Health bar background
    drawRect(
        uiElements.healthBar.x - 2, 
        uiElements.healthBar.y - 2,
        uiElements.healthBar.width + 4,
        uiElements.healthBar.height + 4,
        0.2, 0.2, 0.2, 1
    )
    
    -- Health bar fill
    drawRect(
        uiElements.healthBar.x,
        uiElements.healthBar.y,
        uiElements.healthBar.width * uiElements.healthBar.value,
        uiElements.healthBar.height,
        uiElements.healthBar.color.x,
        uiElements.healthBar.color.y,
        uiElements.healthBar.color.z,
        1
    )
    
    -- Energy bar background
    drawRect(
        uiElements.energyBar.x - 2,
        uiElements.energyBar.y - 2,
        uiElements.energyBar.width + 4,
        uiElements.energyBar.height + 4,
        0.2, 0.2, 0.2, 1
    )
    
    -- Energy bar fill
    drawRect(
        uiElements.energyBar.x,
        uiElements.energyBar.y,
        uiElements.energyBar.width * uiElements.energyBar.value,
        uiElements.energyBar.height,
        uiElements.energyBar.color.x,
        uiElements.energyBar.color.y,
        uiElements.energyBar.color.z,
        1
    )
    
    -- Minimap background
    drawRect(
        uiElements.minimap.x,
        uiElements.minimap.y,
        uiElements.minimap.width,
        uiElements.minimap.height,
        0.1, 0.1, 0.1, 0.8
    )
    
    -- Draw dots on minimap for objects
    for i, obj in ipairs(objects) do
        local minimapX = uiElements.minimap.x + uiElements.minimap.width/2 + obj.pos.x * 20
        local minimapY = uiElements.minimap.y + uiElements.minimap.height/2 + obj.pos.z * 20
        
        drawRect(
            minimapX - 3,
            minimapY - 3,
            6, 6,
            obj.color.x,
            obj.color.y,
            obj.color.z,
            1
        )
    end
    
    -- Draw center dot on minimap
    drawRect(
        uiElements.minimap.x + uiElements.minimap.width/2 - 5,
        uiElements.minimap.y + uiElements.minimap.height/2 - 5,
        10, 10,
        1, 0, 0, 1
    )
    
    window:swapBuffers()
    m3d.pollEvents()
end

-- Cleanup
window:destroy()
m3d.terminate()