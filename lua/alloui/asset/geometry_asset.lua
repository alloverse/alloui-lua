local class = require('pl.class')
local Asset = require ('alloui.asset.asset')
local array2d = require('pl.array2d')
local dump = require('pl.pretty').dump

local GeometryAsset = class.GeometryAsset(Asset)

function GeometryAsset:_init(vertices, uvs, normals, triangles)
    if vertices.triangles then
        uvs = uvs or vertices.uvs
        normals = normals or vertices.normals
        triangles = triangles or vertices.triangles
        vertices = vertices.vertices or vertices
    end
    local s = ""
    for i,v in ipairs(vertices or {}) do
        s = s .. "v "..v[1].." "..v[2].." "..v[3].."\n"
    end
    for i,vt in ipairs(uvs or {}) do
        s = s .. "vt "..vt[1].." "..vt[2].."\n"
    end
    for i,vn in ipairs(normals or {}) do
        s = s .. "vn "..vn[1].." "..vn[2].." "..vn[3].."\n"
    end
    for i,t in ipairs(triangles or {}) do
        local a = t[1]+1
        local b = t[2]+1
        local c = t[3]+1
        if uvs and normals then
            a = a.."/"..a.."/"..a
            b = b.."/"..b.."/"..b
            c = c.."/"..c.."/"..c
        elseif normals then
            a = a.."//"..a
            b = b.."//"..b
            c = c.."//"..c
        elseif uvs then
            a = a.."/"..a
            b = b.."/"..b
            c = c.."/"..c
        end
        s = s .. "f "..a.." "..b.." "..c.."\n"
    end
    self:super(s)
end

--- Create the geometry for a 9patch texture.
-- The texture applied will appear stretched in the center portion but not at the inset edges and corners.
--
-- @tparam number width With of the final geometry
-- @tparam number height Height of the final geometry
-- @tparam number imageWidth The pixel width of the texture to be used
-- @tparam number imageHeight The pixel height of  the texture to be used
-- @tparam number imageInsetX The left and right number of pixles that should not be stretched
-- @tparam number imageInsetY The top and bottom number of pixles that should not be stretched
-- @treturn Asset The generated model
function GeometryAsset.make9PatchGeometry(width, height, imageWidth, imageHeight, imageInsetX, imageInsetY)
    assert(imageWidth > 0, "may not be zero")
    assert(imageHeight > 0, "may not be zero")
    assert(imageWidth > imageInsetX*2, "Must leave some room for the centerpiece")
    assert(imageHeight > imageInsetY*2, "Must leave some room for the centerpiece")
    local sx = imageInsetX/imageWidth
    local sy = imageInsetY/imageHeight
    local x1 = width/2
    local x2 = x1 - width * sx / 2
    local y1 = height/2
    local y2 = y1 - height * sy / 2
    
    local verts = { 
        {-x1,y1,0}, {-x2,y1,0}, {x2,y1,0}, {x1,y1,0},
        {-x1,y2,0}, {-x2,y2,0}, {x2,y2,0}, {x1,y2,0},
        {-x1,-y2,0}, {-x2,-y2,0}, {x2,-y2,0}, {x1,-y2,0},
        {-x1,-y1,0}, {-x2,-y1,0}, {x2,-y1,0}, {x1,-y1,0},
    }
    local norms = {
        {0, 0, 1}, {0, 0, 1}, {0, 0, 1}, {0, 0, 1}, 
        {0, 0, 1}, {0, 0, 1}, {0, 0, 1}, {0, 0, 1}, 
        {0, 0, 1}, {0, 0, 1}, {0, 0, 1}, {0, 0, 1}, 
        {0, 0, 1}, {0, 0, 1}, {0, 0, 1}, {0, 0, 1}, 
    }
    local uvs = {
        {0, 1}, {sx, 1}, {1-sx, 1}, {1, 1},
        {0, 1-sy}, {sx,1-sy}, {1-sx,1-sy}, {1, 1-sy},
        {0 ,sy}, {sx,sy}, {1-sx,sy}, {1,sy},
        {0 ,0 }, {sx,0 }, {1-sx,0 }, {1, 0},
    }
    local tris = {
        {0, 4, 5}, {0, 5, 1}, {1, 5, 6}, {1, 6, 2}, {2, 6, 7}, {2, 7, 3},
        {4, 8, 9}, {4, 9, 5}, {5, 9, 10}, {5, 10, 6}, {6, 10, 11}, {6, 11, 7},
        {8, 12, 13}, {8, 13, 9}, {9, 13, 14}, {9, 14, 10}, {10, 14, 15}, {10, 15, 11},
    }
    return GeometryAsset(verts, uvs, norms, tris)
end

return GeometryAsset
