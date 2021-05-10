local class = require('pl.class')
local tablex = require('pl.tablex')

AssetCache = class.AssetCache()
function AssetCache:_init()
    self.store = {}
    self.maxCount = 100
end
function AssetCache:get(name)
    local asset = self.store[name]
    if asset then self:lastUsed(name, os.time()) end
    return asset
end
function AssetCache:put(asset)
    local name = asset:id()
    self.store[name] = asset
    self:lastUsed(name, os.time())
    self:prune()
end
function AssetCache:remove(name)
    if name.id then name = name:id() end
    self.store[name] = nil
end
function AssetCache:lastUsed(name, newValue)
    local asset = self.store[name]
    if not asset then return nil end
    if newValue then asset.lru = newValue end
    return asset.lru
end
function AssetCache:count()
    return tablex.size(self.store)
end
function AssetCache:allNames()
    return tablex.keys(self.store)
end
function AssetCache:prune()
    print("Pruning ", self.maxCount)
    if self:count() > self.maxCount then
        local time = os.time()
        local list = self:allNames()
        table.sort(list, function(a, b) 
            return self:lastUsed(a) < self:lastUsed(b)
        end)

        for _, name in ipairs(list) do
            print("Removing " .. name)
            if true or time - self:lastUsed(name) > 60 then -- force it to stay for a minute or so just to be nice
                self:remove(name)
            end
            if self:count() <= self.maxCount then 
                return
            end
        end
    end
end

return AssetCache
