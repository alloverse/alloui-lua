local class = require('pl.class')
local types = require ('pl.types')
local allonet = require('alloui.ffi_allonet_handle')
local ffi = require("ffi")
local FileWrapper = require 'alloui.asset.file_wrapper'
local GetImageWidthHeight = require 'alloui.asset.get_image_width_height'

Model = class.Model()

function Model:_init(asset)
    self.asset = asset
    if not allonet.allo_gltf_load(asset:id(), asset:read(), asset:size()) then
        error("Failed to load model from asset " .. asset:id())
    end
end

function Model:getAABB()
    local bb = ffi.new("allo_gltf_bb")
    allonet.allo_gltf_get_aabb(self.asset:id(), bb)
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
    allonet.allo_gltf_unload(self.asset:id())
end

return Model
