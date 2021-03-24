--- Represents data that can be shared to other clients in the Alloverse
--  
-- An asset is just raw data.
-- @see AssetManager
-- @see FileAsset
-- @see Base64Asset
-- @see AssetView
-- @classmod Asset

local class = require('pl.class')
local types = require ('pl.types')

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
    return string.sub(self.data, offset, offset + length - 1)
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

--- Returns a computed unique identifier for this asset
-- The id is a hash of the asset data. This ensures the same asset identifier is always matched with the same data
-- @tparam boolean refresh By default a cached hash is returned, if one is available. Send `refresh` to true to recompute the id
function Asset:id(refresh)
    if self._id == nil or refresh then
        local data = self.data or self:read(1, self:size())
        if data == nil then return nil end
        self._id = allonet.asset_generate_identifier(data)
    end
    return self._id
end


return Asset