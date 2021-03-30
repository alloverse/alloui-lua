local class = require('pl.class')
local tablex = require('pl.tablex')
local AssetCache = require ('alloui.asset.asset_cache')

AssetDiskCache = class.AssetDiskCache(AssetCache)
function AssetDiskCache:_init()
    self:super()
    self.state = {}
    self.rootPath = "assetCache"
    print("Disk cache path: " .. lovr.filesystem.getSaveDirectory() .. "/" .. self.rootPath)
    lovr.filesystem.createDirectory(self.rootPath)
end
function AssetDiskCache:pathFor(name)
    if name:match(":") then 
        name = name:match(".*:(.+)")
    end
    return self.rootPath .. "/" .. name
end
function AssetDiskCache:put(asset)
    local path = self:pathFor(asset:id())
    if not lovr.filesystem.isFile(path) then 
        lovr.filesystem.write(path, asset:read())
        self:lastUsed(asset:id(), os.time())
    end
end
function AssetDiskCache:get(name)
    local path = self:pathFor(name)
    if lovr.filesystem.isFile(path) then
        self:lastUsed(name, os.time())
        return Asset.LovrFile(path)
    end
end
function AssetDiskCache:remove(name)
    local path = self:pathFor(name)
    lovr.filesystem.remove(path)
end
function AssetDiskCache:count()
    local items = lovr.filesystem.getDirectoryItems(self.rootPath) or {}
    return #items
end
function AssetDiskCache:allNames()
    return tablex.keys(self.state)
end
function AssetDiskCache:lastUsed(name, newValue)
    if newValue then self.state[name] = newValue end
    return self.state[name] or 0
end

return AssetDiskCache