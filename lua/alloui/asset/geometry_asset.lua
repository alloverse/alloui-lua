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

return GeometryAsset