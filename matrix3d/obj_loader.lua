local Mesh = require("matrix3d.mesh")

local ObjLoader = {}

local function split(str, delimiter)
    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

local function parseFloat(str)
    return tonumber(str) or 0
end

function ObjLoader.load(filename)
    local file = io.open(filename, "r")
    if not file then
        error("Failed to open file: " .. filename)
    end
    
    local positions = {}
    local texcoords = {}
    local normals = {}
    local vertices = {}
    local indices = {}
    local indexMap = {}
    local indexCounter = 0
    
    for line in file:lines() do
        local tokens = split(line, " ")
        
        if tokens[1] == "v" then
            -- Vertex position
            table.insert(positions, {
                parseFloat(tokens[2]),
                parseFloat(tokens[3]),
                parseFloat(tokens[4])
            })
            
        elseif tokens[1] == "vt" then
            -- Texture coordinate
            table.insert(texcoords, {
                parseFloat(tokens[2]),
                parseFloat(tokens[3])
            })
            
        elseif tokens[1] == "vn" then
            -- Normal
            table.insert(normals, {
                parseFloat(tokens[2]),
                parseFloat(tokens[3]),
                parseFloat(tokens[4])
            })
            
        elseif tokens[1] == "f" then
            -- Face
            local faceIndices = {}
            
            for i = 2, #tokens do
                local vertexData = split(tokens[i], "/")
                local posIndex = tonumber(vertexData[1])
                local texIndex = tonumber(vertexData[2] or "0")
                local normIndex = tonumber(vertexData[3] or "0")
                
                -- OBJ indices are 1-based, convert to 0-based
                posIndex = posIndex > 0 and posIndex or (#positions + posIndex + 1)
                texIndex = texIndex > 0 and texIndex or (texIndex < 0 and (#texcoords + texIndex + 1) or 0)
                normIndex = normIndex > 0 and normIndex or (normIndex < 0 and (#normals + normIndex + 1) or 0)
                
                local key = posIndex .. "/" .. texIndex .. "/" .. normIndex
                
                if not indexMap[key] then
                    -- Add vertex data
                    local pos = positions[posIndex] or {0, 0, 0}
                    table.insert(vertices, pos[1])
                    table.insert(vertices, pos[2])
                    table.insert(vertices, pos[3])
                    
                    local norm = normals[normIndex] or {0, 0, 1}
                    table.insert(vertices, norm[1])
                    table.insert(vertices, norm[2])
                    table.insert(vertices, norm[3])
                    
                    local tex = texcoords[texIndex] or {0, 0}
                    table.insert(vertices, tex[1])
                    table.insert(vertices, tex[2])
                    
                    indexMap[key] = indexCounter
                    indexCounter = indexCounter + 1
                end
                
                table.insert(faceIndices, indexMap[key])
            end
            
            -- Triangulate face (assuming convex polygons)
            for i = 2, #faceIndices - 1 do
                table.insert(indices, faceIndices[1])
                table.insert(indices, faceIndices[i])
                table.insert(indices, faceIndices[i + 1])
            end
        end
    end
    
    file:close()
    
    return Mesh.new(vertices, indices, {
        {size = 3}, -- position
        {size = 3}, -- normal
        {size = 2}  -- texcoord
    })
end

return ObjLoader