--- A type of Asset generated from a file
-- @classmod LovrFileAsset

if not lovr then return nil end

local class = require('pl.class')
local Asset = require ('alloui.asset.asset')

LovrFileAsset = class.LovrFileAsset(Asset)

---
--
--~~~ lua
-- my_asset = LovrFileAsset(path, load)
--~~~
--
-- @tparam string path The path to the file
-- @treturn LovrFileAsset The generated LovrFileAsset
function LovrFileAsset:_init(path)
    assert(lovr.filesystem.isFile(path), path .. " does not exist")
    self._path = path
end

--- Get the path to a LovrFileAsset
--
--~~~ lua
-- path = LovrFileAsset:path()
--~~~
--
-- @treturn string The path to the LovrFileAsset
function LovrFileAsset:path()
    return self._path
end

--- Get the size of a LovrFileAsset
--
--~~~ lua
-- path = LovrFileAsset:size()
--~~~
--
-- @treturn string The size, in bytes, of the LovrFileAsset
function LovrFileAsset:size()
    return lovr.filesystem.getSize(self:path())
end

function LovrFileAsset:read(offset, length)
    local path = self:path()
    if not lovr.filesystem.isFile(path) then return nil end

    if not offset then offset = 1 end
    if not length then length = self:size() - (offset - 1) end
    local contents = lovr.filesystem.read(self:path(), offset + length)
    return contents:sub(offset, offset + length - 1)
end

function LovrFileAsset:write(data, offset)
    offset = offset or 1
    local content = self:read()
    data = content:sub(1, offset - 1) .. data .. content:sub(offset + #data, -1)
    lovr.filesystem.write(self:path(), data)
end

return LovrFileAsset
