local class = require('pl.class')
local allonet = require('alloui.ffi_allonet_handle')
local ffi = require("ffi")

Model = class.Model()

function Model:_init(asset)
    self.asset = asset
    self.loaded = false
end

function Model:load()
    if self.loaded then 
        return true
    end
    if not allonet.allo_gltf_load(self.asset:id(), self.asset:read(), self.asset:size()) then
        return false
    end
    self.loaded = true
    return true
end

--- Return the models bounding box as a table
--
-- @return The AABB {min={x=,y=,z=}, max={x=,y=,z=}, center={x=,y=,z=}, size={x=,y=,z=}}
function Model:getAABB()
    if not self:load() then 
        return  nil
    end
    local bb = ffi.new("allo_gltf_bb")
    if not allonet.allo_gltf_get_aabb(self.asset:id(), bb) then 
        return nil
    end
    return {
        min = {
            x = bb.min.x,
            y = bb.min.y,
            z = bb.min.z
        }, 
        max = {
            x = bb.max.x,
            y = bb.max.y,
            z = bb.max.z
        },
        center = {
            x = (bb.min.x + bb.max.x) / 2,
            y = (bb.min.y + bb.max.y) / 2,
            z = (bb.min.z + bb.max.z) / 2,
        },
        size = {
            x = bb.max.x - bb.min.x,
            y = bb.max.y - bb.min.y,
            z = bb.max.z - bb.min.z,
        }
    }
end

function Model:__gc()
    print("Model unloading")
    self.loaded = false
    allonet.allo_gltf_unload(self.asset:id())
end

return Model
