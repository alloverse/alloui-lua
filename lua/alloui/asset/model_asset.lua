local class = require('pl.class')
local types = require ('pl.types')
local allonet = require('alloui.ffi_allonet_handle')
local ffi = require("ffi")
local FileWrapper = require 'alloui.asset.file_wrapper'
local GetImageWidthHeight = require 'alloui.asset.get_image_width_height'

Model = class.Model()

function Model:_init(asset)
    self.asset = asset
    if not allonet.allo_gltf_load(asset.id(), asset.data, asset.size()) then
        error("Failed to load model from asset " .. asset.id())
    end
end

function Model:getAABB()
    local bb = ffi.new("allo_gltf_bb")
    allonet.allo_gltf_get_aabb(self.asset.id(), bb)
    return bb
end

function Model:__gc()
    print("Model unloading")
    allonet.allo_gltf_unload(self.asset.id())
end
