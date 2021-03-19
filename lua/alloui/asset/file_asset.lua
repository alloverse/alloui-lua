--- A type of Asset generated from a file
-- @classmod FileAsset

local class = require('pl.class')
local Asset = require ('alloui.asset.asset')

FileAsset = class.FileAsset(Asset)

---
--
--~~~ lua
-- my_asset = FileAsset(path, load)
--~~~
--
-- @tparam string path The path to the file
-- @tparam boolean load ???
-- @treturn FileAsset The generated FileAsset
function FileAsset:_init(path, load)
    self._path = path
    self._file = assert(io.open(path, "r+b"))
    if load then
        self.data = self:read(1, self:size())
    end
end

--- Get the path to a FileAsset
--
--~~~ lua
-- path = FileAsset:path()
--~~~
--
-- @treturn string The path to the FileAsset
function FileAsset:path()
    return self._path
end

--- Get the size of a FileAsset
--
--~~~ lua
-- path = FileAsset:size()
--~~~
--
-- @treturn string The size, in bytes, of the FileAsset
function FileAsset:size()
    if self._size == nil then
        self._size = self._file:seek("end")
    end
    return self._size
end

-- callback: function(data)
function FileAsset:read(offset, length)
    self._file:seek("set", offset - 1) -- offset is 1-based but seek is 0-based
    local contents = assert(self._file:read(length))
    return contents
end

function FileAsset:write(data, offset)
    self.file:seek(offset - 1) -- offset is 1-based but seek is 0-based
    self.file:write(data)
end

return FileAsset
