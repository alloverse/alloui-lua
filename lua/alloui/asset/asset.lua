--- Represents data that can be shared to other clients in the Alloverse
--  
-- An asset is just raw data.
-- @see AssetManager
-- @see FileAsset
-- @see Base64Asset
-- @classmod Asset

local class = require('pl.class')
local types = require ('pl.types')
local allonet = require('alloui.ffi_allonet_handle')
local ffi = require("ffi")
local FileWrapper = require 'alloui.asset.file_wrapper'
local GetImageWidthHeight = require 'alloui.asset.get_image_width_height'
local Model = require 'alloui.asset.model_asset'

Asset = class.Asset()

--- Assets are considered equal if their hashes match
function Asset.__eq(a, b)
    if getmetatable(a) ~= Asset or getmetatable(b) ~= Asset then return false end
    return a:id() == b:id()
end

function Asset:__tostring()
    if self:id() then 
        return self._name .. "<" .. self:id() .. ">"
    else
        return "Empty " .. self._name
    end
end

---
--
--~~~ lua
-- asset = Asset(data)
--~~~
--
-- @tparam string data Raw data for the asset.
function Asset:_init(data)
    self.data = data
    self._id = nil
end

--- Read a part of the data
-- @tparam number offset The byte to start reading from
-- @tparam number length The number of bytes to read
-- @treturn string the requested data
function Asset:read(offset, length)
    if self.data == nil then return nil end
    if not offset then offset = 1 end
    if not length then length = self:size() - (offset - 1) end
    return self.data:sub(offset, offset + length - 1)
end

--- Write a part of the data
-- @tparam string data The data buffering
-- @tparam number offset The byte offset to start writing at
-- @tparam number totalSize The expected total size of the asset.
function Asset:write(data, offset, totalSize)
    if self.data == nil then
        self.data = data
    else
        self.data = self.data .. data
    end
end

--- Returns the size of the asset
-- @treturn number The size of the data
function Asset:size()
    if self.data == nil then return 0 end
    return string.len(self.data)
end

--- Returns the pixel width and height of the asset that represents an image. Returns nil if the asset doesn't represent an image.
-- @treturn (number, number) The width and height of the image (in pixels)
function Asset:getImageWidthHeight()
    return GetImageWidthHeight(self:like_file())
end

--- Returns a computed unique identifier for this asset
-- The id is a hash of the asset data. This ensures the same asset identifier is always matched with the same data
-- @tparam boolean refresh By default a cached hash is returned, if one is available. Send `refresh` to true to recompute the id
function Asset:id(refresh)
    if self._id == nil or refresh then
        local data = self.data or self:read()
        if data == nil then return nil end
        local cstr = allonet.asset_generate_identifier(data, #data)
        self._id = ffi.string(cstr)
        ffi.C.free(cstr)
    end
    return self._id
end

--- Returns a File-like wrapper to send to methods that wants files
-- It's not fully implemented; Fill out methods as needed.
-- @treturn FileWrapper An object that implmeents the same methods as io.File
function Asset:like_file()
    return FileWrapper(self)
end

function Asset:model()
    return Model(self)
end

return Asset
