package.path = package.path .. ";./?.lua;./?/init.lua"

local m3d = require("matrix3d")
local ffi = require("ffi")

-- Add GLFW key functions
ffi.cdef[[
    int glfwGetKey(GLFWwindow* window, int key);
]]

local glfw = ffi.load("glfw")

-- Key codes
local GLFW_KEY_W = 87
local GLFW_KEY_A = 65
local GLFW_KEY_S = 83
local GLFW_KEY_D = 68
local GLFW_PRESS = 1

-- Create window
local window = m3d.createWindow(1024, 768, "Collision System Demo - WASD to move")

-- Shaders and meshes
local shader = m3d.Shader.new(m3d.Shader.default3D.vertex, m3d.Shader.default3D.fragment)
local cube = m3d.Mesh.cube(1.0)

-- Player with collision box
local player = {
    pos = m3d.vec3(0, 0, 0),
    size = m3d.vec3(1, 1, 1),
    speed = 0.1,
    color = m3d.vec3(0.2, 0.4, 0.8)
}

-- Create collision box for player
player.collider = m3d.collision.Box.new(
    player.pos.x - player.size.x/2,
    player.pos.y - player.size.y/2,
    player.pos.z - player.size.z/2,
    player.size.x, player.size.y, player.size.z
)

-- Obstacles with collision boxes
local obstacles = {
    {
        pos = m3d.vec3(3, 0, 0),
        size = m3d.vec3(2, 2, 2),
        color = m3d.vec3(0.8, 0.2, 0.2)
    },
    {
        pos = m3d.vec3(-3, 0, 3),
        size = m3d.vec3(1.5, 1.5, 1.5),
        color = m3d.vec3(0.2, 0.8, 0.2)
    },
    {
        pos = m3d.vec3(0, 0, -3),
        size = m3d.vec3(1, 3, 1),
        color = m3d.vec3(0.8, 0.8, 0.2)
    }
}

-- Create collision boxes for obstacles
for _, obs in ipairs(obstacles) do
    obs.collider = m3d.collision.Box.new(
        obs.pos.x - obs.size.x/2,
        obs.pos.y - obs.size.y/2,
        obs.pos.z - obs.size.z/2,
        obs.size.x, obs.size.y, obs.size.z
    )
end

-- Collectible spheres
local spheres = {
    {pos = m3d.vec3(5, 0, 5), radius = 0.5, collected = false},
    {pos = m3d.vec3(-5, 0, -5), radius = 0.5, collected = false},
    {pos = m3d.vec3(-5, 0, 5), radius = 0.5, collected = false},
    {pos = m3d.vec3(5, 0, -5), radius = 0.5, collected = false}
}

-- Create collision spheres
for _, sphere in ipairs(spheres) do
    sphere.collider = m3d.collision.Sphere.new(
        sphere.pos.x, sphere.pos.y, sphere.pos.z, sphere.radius
    )
end

local score = 0

-- Camera setup
local cameraDistance = 15
local cameraHeight = 10
local cameraAngle = 0

-- Helper function
local function isKeyPressed(key)
    return glfw.glfwGetKey(window.handle, key) == GLFW_PRESS
end

print("=== COLLISION DEMO ===")
print("WASD to move")
print("Collect yellow spheres!")
print("Red = Solid obstacles")
print("====================")

-- Main loop
while not window:shouldClose() do
    -- Store old position
    local oldPos = m3d.vec3(player.pos.x, player.pos.y, player.pos.z)
    
    -- Input
    local moveX, moveZ = 0, 0
    if isKeyPressed(GLFW_KEY_W) then moveZ = -1 end
    if isKeyPressed(GLFW_KEY_S) then moveZ = 1 end
    if isKeyPressed(GLFW_KEY_A) then moveX = -1 end
    if isKeyPressed(GLFW_KEY_D) then moveX = 1 end
    
    -- Normalize diagonal movement
    local moveLen = math.sqrt(moveX * moveX + moveZ * moveZ)
    if moveLen > 0 then
        moveX = moveX / moveLen * player.speed
        moveZ = moveZ / moveLen * player.speed
    end
    
    -- Update position
    player.pos.x = player.pos.x + moveX
    player.pos.z = player.pos.z + moveZ
    
    -- Update player collision box
    player.collider:setCenter(player.pos.x, player.pos.y, player.pos.z)
    
    -- Check collision with obstacles
    local colliding = false
    for _, obs in ipairs(obstacles) do
        if player.collider:intersects(obs.collider) then
            colliding = true
            -- Revert to old position
            player.pos.x = oldPos.x
            player.pos.z = oldPos.z
            player.collider:setCenter(player.pos.x, player.pos.y, player.pos.z)
            break
        end
    end
    
    -- Check sphere collection using sphere collision
    for _, sphere in ipairs(spheres) do
        if not sphere.collected then
            -- Check if player (treated as sphere) collides with collectible
            local playerRadius = math.min(player.size.x, player.size.y, player.size.z) / 2
            if m3d.collision.checkSphere3D(
                player.pos.x, player.pos.y, player.pos.z, playerRadius,
                sphere.pos.x, sphere.pos.y, sphere.pos.z, sphere.radius
            ) then
                sphere.collected = true
                score = score + 1
                print("Collected! Score: " .. score)
            end
        end
    end
    
    -- Update camera
    cameraAngle = cameraAngle + 0.005
    local cameraPos = m3d.vec3(
        math.cos(cameraAngle) * cameraDistance,
        cameraHeight,
        math.sin(cameraAngle) * cameraDistance
    )
    
    -- Clear and render
    window:clear(0.1, 0.1, 0.15, 1.0)
    
    shader:use()
    local view = m3d.Matrix4.lookAt(cameraPos, m3d.vec3(0, 0, 0), m3d.vec3(0, 1, 0))
    local projection = m3d.Matrix4.perspective(math.rad(60), window.fbWidth/window.fbHeight, 0.1, 100)
    
    shader:setMat4("view", view)
    shader:setMat4("projection", projection)
    shader:setVec3("lightPos", 5, 10, 5)
    shader:setVec3("lightColor", 1, 1, 1)
    
    -- Draw floor grid
    for x = -10, 10, 2 do
        for z = -10, 10, 2 do
            local model = m3d.Matrix4.translate(x, -0.5, z) *
                         m3d.Matrix4.scale(0.9, 0.1, 0.9)
            shader:setMat4("model", model)
            shader:setVec3("objectColor", 0.3, 0.3, 0.3)
            cube:draw()
        end
    end
    
    -- Draw player
    local playerModel = m3d.Matrix4.translate(player.pos.x, player.pos.y, player.pos.z) *
                       m3d.Matrix4.scale(player.size.x, player.size.y, player.size.z)
    shader:setMat4("model", playerModel)
    if colliding then
        shader:setVec3("objectColor", 1, 0.5, 0.5)  -- Red tint when colliding
    else
        shader:setVec3("objectColor", player.color.x, player.color.y, player.color.z)
    end
    cube:draw()
    
    -- Draw obstacles
    for _, obs in ipairs(obstacles) do
        local model = m3d.Matrix4.translate(obs.pos.x, obs.pos.y, obs.pos.z) *
                     m3d.Matrix4.scale(obs.size.x, obs.size.y, obs.size.z)
        shader:setMat4("model", model)
        shader:setVec3("objectColor", obs.color.x, obs.color.y, obs.color.z)
        cube:draw()
    end
    
    -- Draw spheres
    for _, sphere in ipairs(spheres) do
        if not sphere.collected then
            -- Using cube mesh scaled to approximate sphere
            local model = m3d.Matrix4.translate(sphere.pos.x, sphere.pos.y, sphere.pos.z) *
                         m3d.Matrix4.scale(sphere.radius * 2, sphere.radius * 2, sphere.radius * 2)
            shader:setMat4("model", model)
            shader:setVec3("objectColor", 1, 1, 0)
            cube:draw()
        end
    end
    
    -- Update title
    glfw.glfwSetWindowTitle(window.handle, 
        "Collision Demo - Score: " .. score .. "/4 | " .. 
        (colliding and "COLLISION!" or "Moving freely"))
    
    window:swapBuffers()
    m3d.pollEvents()
end

-- Cleanup
window:destroy()
m3d.terminate()

print("\nFinal Score: " .. score .. "/4")
print("Thanks for testing the collision system!")