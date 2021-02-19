--- 
-- @classmod FileAsset

local class = require('pl.class')
local Asset = require ('asset')

FileAsset = class.FileAsset(Asset)

function FileAsset:_init(path)
    self._path = path
    self._file = assert(io.open(path, "r+b"))
end

function FileAsset:path()
    return self._path
end

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
