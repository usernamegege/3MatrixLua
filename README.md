# 🎮 3MatrixLua

A pure Lua 3D/2D graphics framework that actually works! No C compilation, no build tools, just `luajit` and go! 🚀

![License](https://img.shields.io/badge/license-BRO-yellow.svg)
![LuaJIT](https://img.shields.io/badge/LuaJIT-2.1-blue.svg)
![OpenGL](https://img.shields.io/badge/OpenGL-3.3-green.svg)

![3D Cube Demo](Cube%20Made%20with%203Matrix.png)

## 🤔 Why 3MatrixLua?

Because Lua deserves a proper 3D framework! While other languages have Three.js, Unity, or Godot, Lua developers have been stuck with... not much. Until now!

**3MatrixLua** is:
- 🎯 **Pure Lua** - No C compilation needed
- 🏃 **Fast** - Uses LuaJIT FFI for native OpenGL calls
- 🎨 **Simple** - Clean API that gets out of your way
- 🎮 **Game-Ready** - Built for real-time 2D/3D graphics
- 🛠️ **Hackable** - It's just Lua files, tweak anything!

## ✨ Features

- ✅ 2D and 3D rendering
- ✅ Built-in math library (vectors, matrices, quaternions)
- ✅ Shader support with sensible defaults
- ✅ Mesh generation (triangles, quads, cubes)
- ✅ OBJ model loading
- ✅ Window management via GLFW
- ✅ Built-in collision detection (AABB, Sphere)
- ✅ Cross-platform (macOS, Linux, Windows)
- 🚧 FBX model loading (coming soon)
- 🚧 Physics integration (coming soon)

## 🚀 Quick Start

### Prerequisites

You need:
- **LuaJIT** (regular Lua won't work, we need that FFI magic!)
- **OpenGL 3.3+** (comes with your OS)
- **GLFW3** (for window management)

### Installation

#### macOS
```bash
brew install luajit glfw
```

#### Ubuntu/Debian
```bash
sudo apt-get install luajit libglfw3-dev
```

#### Windows
- Install [LuaJIT](https://luajit.org/download.html)
- Install [GLFW](https://www.glfw.org/download.html)

### Your First Triangle!

```lua
local m3d = require("matrix3d")

-- Create window
local window = m3d.createWindow(800, 600, "My First Triangle!")

-- Create shader and triangle
local shader = m3d.Shader.new(m3d.Shader.default2D.vertex, m3d.Shader.default2D.fragment)
local triangle = m3d.Mesh.triangle()

-- Setup 2D projection
local projection = m3d.Matrix4.ortho(-1, 1, -1, 1, -1, 1)

-- Main loop
while not window:shouldClose() do
    window:clear(0.1, 0.1, 0.2, 1.0)
    
    shader:use()
    shader:setMat4("projection", projection)
    triangle:draw()
    
    window:swapBuffers()
    m3d.pollEvents()
end
```

Run it:
```bash
luajit examples/2d_triangle.lua
```

## 📚 Examples

Check out the `examples/` folder:

- 🔺 `2d_triangle.lua` - Basic 2D rendering
- 🎲 `3d_cube.lua` - 3D cube with lighting
- 🎮 `cube_collector_game.lua` - Simple game demo
- 🎨 `mixed_2d_3d_demo.lua` - 2D UI + 3D scene
- 🌟 `test_app.lua` - Interactive scene showcase
- 💥 `collision_demo.lua` - Collision detection demo

## 📖 API Documentation

### Window Management

```lua
-- Create a window
local window = m3d.createWindow(width, height, title)

-- Window methods
window:shouldClose()          -- Returns true when user wants to close
window:swapBuffers()          -- Display what you've drawn
window:clear(r, g, b, a)      -- Clear screen with color
window:destroy()              -- Clean up window

-- Global functions
m3d.pollEvents()              -- Process keyboard/mouse events
m3d.terminate()               -- Cleanup GLFW
```

### Math Library

```lua
-- 2D Vectors
local v = m3d.vec2(x, y)
v:length()                    -- Get magnitude
v:normalize()                 -- Unit vector
v:dot(other)                  -- Dot product

-- 3D Vectors  
local v = m3d.vec3(x, y, z)
v:cross(other)                -- Cross product
v + other                     -- Vector addition
v * scalar                    -- Scalar multiplication

-- 4x4 Matrices
m3d.Matrix4.identity()
m3d.Matrix4.translate(x, y, z)
m3d.Matrix4.scale(x, y, z)
m3d.Matrix4.rotateX/Y/Z(radians)
m3d.Matrix4.perspective(fov, aspect, near, far)
m3d.Matrix4.ortho(left, right, bottom, top, near, far)
m3d.Matrix4.lookAt(eye, target, up)
```

### Shaders

```lua
-- Create custom shader
local shader = m3d.Shader.new(vertexSource, fragmentSource)

-- Use built-in shaders
local shader2D = m3d.Shader.new(
    m3d.Shader.default2D.vertex,
    m3d.Shader.default2D.fragment
)

-- Set uniforms
shader:use()                          -- Activate shader
shader:setFloat("time", value)
shader:setVec2("resolution", x, y)
shader:setVec3("color", r, g, b)
shader:setVec4("tint", r, g, b, a)
shader:setMat4("mvpMatrix", matrix)
```

### Meshes

```lua
-- Built-in shapes
local triangle = m3d.Mesh.triangle()
local quad = m3d.Mesh.quad(width, height)  
local cube = m3d.Mesh.cube(size)

-- Custom mesh
local vertices = {
    -- x, y, z,  r, g, b
    -0.5, 0.0, 0.0,  1, 0, 0,
     0.5, 0.0, 0.0,  0, 1, 0,
     0.0, 1.0, 0.0,  0, 0, 1
}
local mesh = m3d.Mesh.new(vertices, indices, {
    {size = 3},  -- position
    {size = 3}   -- color
})

-- Draw
mesh:draw()
```

### Model Loading

```lua
-- Load OBJ model
local model = m3d.ObjLoader.load("path/to/model.obj")
model:draw()
```

### Collision Detection

```lua
-- AABB (Box) collision
local box1 = m3d.collision.Box.new(x, y, z, width, height, depth)
local box2 = m3d.collision.Box.new(x2, y2, z2, w2, h2, d2)
if box1:intersects(box2) then
    -- Collision detected!
end

-- Sphere collision
local sphere = m3d.collision.Sphere.new(x, y, z, radius)
if sphere:intersects(box1) then
    -- Sphere hit box!
end

-- Simple collision check functions
if m3d.collision.checkAABB3D(x1, y1, z1, w1, h1, d1, x2, y2, z2, w2, h2, d2) then
    -- Boxes collide
end

if m3d.collision.checkSphere3D(x1, y1, z1, r1, x2, y2, z2, r2) then
    -- Spheres collide
end
```

## 🎮 Complete Game Example

```lua
local m3d = require("matrix3d")

local window = m3d.createWindow(800, 600, "Spinning Cube")
local shader = m3d.Shader.new(m3d.Shader.default3D.vertex, m3d.Shader.default3D.fragment)
local cube = m3d.Mesh.cube(1.0)

local projection = m3d.Matrix4.perspective(math.rad(45), 800/600, 0.1, 100)
local view = m3d.Matrix4.lookAt(m3d.vec3(3,3,3), m3d.vec3(0,0,0), m3d.vec3(0,1,0))

while not window:shouldClose() do
    window:clear(0.1, 0.1, 0.1, 1.0)
    
    shader:use()
    shader:setMat4("model", m3d.Matrix4.rotateY(os.clock()))
    shader:setMat4("view", view)
    shader:setMat4("projection", projection)
    shader:setVec3("lightPos", 5, 5, 5)
    shader:setVec3("lightColor", 1, 1, 1)
    shader:setVec3("objectColor", 1, 0.5, 0.3)
    
    cube:draw()
    
    window:swapBuffers()
    m3d.pollEvents()
end
```

## 🏗️ Project Structure

```
3MatrixLua/
├── matrix3d/
│   ├── init.lua       # Main module & window management
│   ├── math.lua       # Vector/Matrix math
│   ├── shader.lua     # Shader compilation & management
│   ├── mesh.lua       # Mesh creation & rendering
│   └── obj_loader.lua # OBJ file parser
├── examples/          # Example programs
├── LICENSE           # BRO License 🤘
└── README.md         # You are here!
```

## 🤝 Contributing

Found a bug? Want to add a feature? PRs welcome! Just:

1. Fork it
2. Create your feature branch (`git checkout -b cool-new-feature`)
3. Commit your changes (`git commit -am 'Add cool feature'`)
4. Push to the branch (`git push origin cool-new-feature`)
5. Create a Pull Request

Remember: Be excellent to each other! 🫶

## 🐛 Troubleshooting

**"Module 'matrix3d' not found"**
- Make sure you're running from the project root or adjust the path

**"3MatrixLua requires LuaJIT"**
- Install LuaJIT, regular Lua doesn't have FFI support

**Black screen/Nothing renders**
- Check your OpenGL version: `glxinfo | grep "OpenGL version"`
- Make sure GLFW is installed correctly

**Retina/HiDPI issues**
- The framework handles this automatically, but check `window.fbWidth/fbHeight`

## 📜 License

Licensed under the **BRO License v1.0** - see [LICENSE](LICENSE) file for details.

TL;DR: Use it, modify it, share it. Just don't do illegal stuff or blame me if it breaks. 🤘

## 🙏 Acknowledgments

- LuaJIT team for the amazing FFI
- GLFW for cross-platform window management  
- The Lua community for being awesome
- You, for checking this out!

---

Made with ❤️ and probably too much ☕

*Remember: Real programmers use Lua for 3D graphics!* 😎