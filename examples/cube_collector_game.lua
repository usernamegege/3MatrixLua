package.path = package.path .. ";./?.lua;./?/init.lua"

local m3d = require("matrix3d")

-- Game window
local window = m3d.createWindow(1024, 768, "Cube Collector - Collect the golden cubes!")

-- Shaders
local shader = m3d.Shader.new(m3d.Shader.default3D.vertex, m3d.Shader.default3D.fragment)

-- Meshes
local cube = m3d.Mesh.cube(1.0)
local floor = m3d.Mesh.quad(30, 30)

-- Game state
local player = {
    pos = m3d.vec3(0, 0.5, 0),
    vel = m3d.vec3(0, 0, 0),
    speed = 0.1,
    size = 0.5
}

local camera = {
    distance = 10,
    height = 8,
    angle = 0
}

local collectibles = {}
local score = 0
local gameTime = 0

-- Create collectible cubes
local function spawnCollectible()
    table.insert(collectibles, {
        pos = m3d.vec3(
            math.random() * 20 - 10,
            0.5,
            math.random() * 20 - 10
        ),
        collected = false,
        bobOffset = math.random() * math.pi * 2
    })
end

-- Spawn initial collectibles
for i = 1, 10 do
    spawnCollectible()
end

-- Check collision
local function checkCollision(pos1, size1, pos2, size2)
    local dx = math.abs(pos1.x - pos2.x)
    local dz = math.abs(pos1.z - pos2.z)
    return dx < (size1 + size2) and dz < (size1 + size2)
end

-- Input handling (simple WASD simulation with automatic movement)
local inputAngle = 0

-- Main game loop
while not window:shouldClose() do
    gameTime = gameTime + 0.016
    
    -- Auto-move player (simulating input)
    inputAngle = inputAngle + 0.02
    player.vel.x = math.cos(inputAngle) * player.speed
    player.vel.z = math.sin(inputAngle) * player.speed
    
    -- Update player position
    player.pos.x = player.pos.x + player.vel.x
    player.pos.z = player.pos.z + player.vel.z
    
    -- Keep player in bounds
    if math.abs(player.pos.x) > 14 then 
        player.pos.x = player.pos.x > 0 and 14 or -14
        inputAngle = inputAngle + math.pi/2
    end
    if math.abs(player.pos.z) > 14 then 
        player.pos.z = player.pos.z > 0 and 14 or -14
        inputAngle = inputAngle + math.pi/2
    end
    
    -- Check collectible collisions
    for i, col in ipairs(collectibles) do
        if not col.collected and checkCollision(player.pos, player.size, col.pos, 0.5) then
            col.collected = true
            score = score + 1
            print("Score: " .. score)
            
            -- Spawn new collectible
            spawnCollectible()
        end
    end
    
    -- Remove collected items
    for i = #collectibles, 1, -1 do
        if collectibles[i].collected then
            table.remove(collectibles, i)
        end
    end
    
    -- Update camera
    camera.angle = camera.angle + 0.005
    local cameraPos = m3d.vec3(
        player.pos.x + math.cos(camera.angle) * camera.distance,
        camera.height,
        player.pos.z + math.sin(camera.angle) * camera.distance
    )
    
    -- Clear and setup rendering
    window:clear(0.1, 0.15, 0.3, 1.0)
    
    shader:use()
    local view = m3d.Matrix4.lookAt(cameraPos, player.pos, m3d.vec3(0, 1, 0))
    local projection = m3d.Matrix4.perspective(math.rad(60), 1024/768, 0.1, 100)
    
    shader:setMat4("view", view)
    shader:setMat4("projection", projection)
    shader:setVec3("lightPos", 0, 20, 0)
    shader:setVec3("lightColor", 1, 1, 1)
    
    -- Draw floor
    local floorModel = m3d.Matrix4.translate(0, 0, 0) * m3d.Matrix4.rotateX(math.rad(-90))
    shader:setMat4("model", floorModel)
    shader:setVec3("objectColor", 0.3, 0.5, 0.3)
    floor:draw()
    
    -- Draw player
    local playerModel = m3d.Matrix4.translate(player.pos.x, player.pos.y, player.pos.z) *
                       m3d.Matrix4.scale(player.size, player.size, player.size) *
                       m3d.Matrix4.rotateY(inputAngle)
    shader:setMat4("model", playerModel)
    shader:setVec3("objectColor", 0.2, 0.4, 0.8)
    cube:draw()
    
    -- Draw collectibles
    for _, col in ipairs(collectibles) do
        local bobY = math.sin(gameTime * 3 + col.bobOffset) * 0.2
        local rotation = gameTime * 2 + col.bobOffset
        
        local colModel = m3d.Matrix4.translate(col.pos.x, col.pos.y + bobY, col.pos.z) *
                        m3d.Matrix4.rotateY(rotation) *
                        m3d.Matrix4.scale(0.4, 0.4, 0.4)
        
        shader:setMat4("model", colModel)
        shader:setVec3("objectColor", 1.0, 0.8, 0.1)  -- Golden color
        cube:draw()
    end
    
    -- Draw some decoration cubes
    for i = -2, 2 do
        for j = -2, 2 do
            if i ~= 0 or j ~= 0 then
                local decorModel = m3d.Matrix4.translate(i * 5, 0.25, j * 5) *
                                  m3d.Matrix4.scale(0.5, 0.5, 0.5)
                shader:setMat4("model", decorModel)
                shader:setVec3("objectColor", 0.5, 0.5, 0.5)
                cube:draw()
            end
        end
    end
    
    window:swapBuffers()
    m3d.pollEvents()
end

-- Cleanup
window:destroy()
m3d.terminate()

print("Game Over! Final Score: " .. score)