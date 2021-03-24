--- A utility class for storage and access to [Assets](Asset).
-- @classmod AssetManager

local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local ffi = require('ffi')
local types = require ('pl.types')

AssetManager = class.AssetManager()

---
--
--~~~ lua
-- assetManager = AssetManager(client)
--~~~
--
-- @tparam Client client ???
function AssetManager:_init(client)
    assert(client, "AssetManager needs the client")
    self.client = client

    self._assets = {
        loading = {}, -- Assets requested but not completed
        cache = {}, -- All assets are put into a weak list and managed while in used
        published = {}, -- Explicitly added assets are also in a strong list to remain in memory

        getTime = function ()
            return os.time()
        end,
        publish = function (self, asset, manage)
            self.cache[asset:id()] = asset
            if manage then 
                self.published[asset:id()] = asset
            end
        end,
        get = function (self, id)
            local asset = self.cache[id]
            if asset then 
                asset.lru = self.getTime()
            end
            return asset
        end,
        put = function(self, asset)
            asset.lru = self.getTime()
            self.cache[asset:id()] = asset
            self:prune()
        end,
        remove = function (self, asset_or_id)
            local asset = asset_or_id.id and asset_or_id:id() or asset_or_id
            self.cache[asset] = nil
            self.published[asset] = nil
            self.loading[asset] = nil
        end,

        prune = function(self)
            local max_items = 100 -- what's a decent value?
            if tablex.size(self.cache) > max_items then
                local time = self.getTime()
                local list = tablex.values(self.cache)
                table.sort(list, function(a, b) 
                    return a.lru < b.lru
                end)

                for _, asset in ipairs(list) do
                    if time - asset.lru > 60 then -- force it to stay for a minute or so just to be nice
                        self:remove(asset)
                    end
                    if tablex.size(self.cache) <= max_items then 
                        return
                    end
                end
            end
        end
    }

    -- make the loaded table weak
    -- setmetatable(self._assets.cache, { __mode = "v" })

    -- For providing assets
    client:set_asset_request_callback(function (name, offset, length)
        self:_handleRequest(name, offset, length)
    end)

    -- Leave unassigned if you are not interrested receiving assets
    client:set_asset_receive_callback(function (name, bytes, offset, total_size)
        self:_handleData(name, bytes, offset, total_size)
    end)

    -- Leave unassigned if you are not interrested in assets
    client:set_asset_state_callback(function (name, state)
        self:_handleState(name, state)
    end)
end

function AssetManager:getStats() 
    return {
        published = tablex.size(self._assets.published),
        loading = tablex.size(self._assets.loading),
        cached = tablex.size(self._assets.cache),
    }
end

--- Adds an Asset to the AssetManager
--
--~~~ lua
-- AssetManager:add(asset, manage)
--~~~
--
-- @tparam [Asset](Asset) asset The Asset to add
-- @tparam bool manage If set to `true`, the AssetManager will hold on to the asset for you. If set to `false`, it will only serve the asset as long as you keep a reference to it.
function AssetManager:add(asset, manage)
    if asset.id then
        print("Adding " .. tostring(asset))
        self._assets:publish(asset, manage)
    elseif types.is_iterable(asset) or types.is_indexable(asset) then
        tablex.foreach(asset, function(asset) self:add(asset, manage) end)
    elseif types.is_indexable(asset) then 
        tablex.foreachi(asset, function(asset) self:add(asset, manage) end)
    else 
        error("not an asset")
    end
end

--- Adds an Asset to the AssetManager
--
--~~~ lua
-- AssetManager:remove(asset)
--~~~
--
-- @tparam [Asset](Asset) asset The Asset to remove
function AssetManager:remove(asset)
    if asset.id then
        print("Removing " .. tostring(asset))
        self._assets.published[asset:id()] = nil
    elseif types.is_iterable(asset) then
        tablex.foreach(asset, function(asset) self:remove(asset) end)
    elseif types.is_indexable(asset) then
        tablex.foreachi(asset, function(asset) self:remove(asset) end)
    else
        error("not an asset")
    end
end


--- Get an Asset with the corresponding name. Returns `false` if no matching Asset is found.
--
--~~~ lua
-- AssetManager:get(name)
--~~~
--
-- @tparam string name The name of the requested string
-- @treturn [Asset](Asset) The corresponding Asset
function AssetManager:get(name)
    return self._assets:get(name)
end


--- Gets all Assets currently held by the AssetManager.
--
--~~~ lua
-- AssetManager:all()
--~~~
--
-- @treturn Table All assets held by the AssetManager
function AssetManager:all()
    return tablex.values(self._assets.cache)
end

--- Get the number of Assets currently held by the AssetManager.
--
--~~~ lua
-- AssetManager:count()
--~~~
--
-- @treturn number The number of assets held by the AssetManager
function AssetManager:count()
    return tablex.size(self._assets.cache)
end


--- ???
--
--~~~ lua
-- AssetManager:load(name, callback)
--~~~
--
-- callback: function(name, asset_or_nil)
-- returns true if the asset is loading. 
-- returns false if asset was found in cache
function AssetManager:load(name, callback)
    local asset = self:get(name)
    if asset then
        callback(name, asset)
        return true
    end

    asset = self:_loading(name)
    if asset then
        local chained = asset.completionCallback
        asset.completionCallback = function (name, x)
            chained(name, x)
            callback(name, x)
        end
        return false
    end

    local asset = Asset()
    asset.completionCallback = callback
    self:_beganLoading(name, asset)
    self.client:asset_request(name)

    return true
end

function AssetManager:_published(name)
    return self._assets.published[name]
end

function AssetManager:_loading(name)
    return self._assets.loading[name]
end

function AssetManager:_beganLoading(name, asset)
    self._assets.loading[name] = asset
end

function AssetManager:_finishedLoading(name, asset)
    self._assets.loading[name] = nil
    if asset and name == asset:id() then
        self._assets:put(asset)
    elseif asset and asset:id() then
        print("Asset id mismatch. Expected " .. name .. " but got " .. asset:id())
    end
end

function AssetManager:_handleRequest(name, offset, length)
    local asset = self:get(name)
    if asset == nil then
        print("Can not serve asset "..name)
        self.client:asset_send(name, nil, offset, 0)
        return
    end

    local chunk = asset:read(offset, length)
    local size = asset:size()

    self.client:asset_send(name, chunk, offset, size)
end

function AssetManager:_handleData(name, bytes, offset, total_size)
    local asset = self:_loading(name)
    if asset == nil then return end
    asset:write(bytes, offset, total_size)
end

function AssetManager:_handleState(name, state)
    local asset = self:_loading(name)
    if asset == nil then return end

    if state == 0 then
        if asset.completionCallback then 
            asset.completionCallback(name, asset)
            asset.completionCallback = nil
        end
    else
        asset.data = nil
        if asset.completionCallback then 
            asset.completionCallback(name, nil)
            asset.completionCallback = nil
        end
        print("Could not fetch asset " .. name .. " (" .. state .. ")")
    end
    self:_finishedLoading(name, asset)
end

return AssetManager