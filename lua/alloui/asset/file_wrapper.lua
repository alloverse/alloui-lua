

local class = require('pl.class')
local types = require ('pl.types')

local FileWrapper = class.FileWrapper()

function FileWrapper:_init(asset)
    self.asset = asset
    self.cursor = 1
    self.size = asset:size()
end

function FileWrapper:seek(from, count)
    if from == "set" then self.cursor = count or 0 end
    if from == "cur" then self.cursor = self.cursor + (count or 0) end
    if from == "end" then self.cursor = self.size end
end

function FileWrapper:close()
end

function FileWrapper:flush()
end

function FileWrapper:read(what)
    if self.cursor >= self.size then return nil end
    if type(what) == "number" then
        local data = self.asset:read(self.cursor, what)
        self.cursor = self.cursor + what
        return data
    end
    if what == "*a" or what == "*all" then
        self.cursor = self.size
        return self.asset:read()
    end
end

function FileWrapper:write()
    error("impement if you need me")
end

function FileWrapper:lines()
    error("impement if you need me")
end

return FileWrapper
