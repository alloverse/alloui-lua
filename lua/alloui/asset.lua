local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local ffi = require('ffi')
local types = require ('pl.types')

AssetManager = class()

function AssetManager:_init(client)
    assert(client, "AssetManager needs the client")
    self.client = client

    self._assets = {
        loading = {},
        published = {}
    }

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

function AssetManager:add(asset)
    if asset.id then
        print("adding "..asset:id())
        table.insert(self._assets.published, asset)
    elseif types.is_indexable(asset) then 
        tablex.foreachi(asset, function(asset) self:add(asset) end)
    elseif types.is_iterable(asset) then
        tablex.foreach(asset, function(asset) self:add(asset) end)
    else 
        error("not an asset")
    end
end

function AssetManager:remove(asset)
    if asset.id then
        for i, v in ipairs(self._assets.published) do
            if v == asset then
                table.remove(self._assets.published, i)
                return;
            end
        end
    elseif types.is_indexable(asset) then
        tablex.foreachi(asset, function(asset) self:remove(asset) end)
    elseif types.is_iterable(asset) then
        tablex.foreach(asset, function(asset) self:remove(asset) end)
    else
        error("not an asset")
    end
end

function AssetManager:get(name_or_index)
    if type(name_or_index) == "string" then
        return self:_published(name_or_index)
    elseif type(name_or_index) == "number" then
        return self:all()[name_or_index]
    end
end

function AssetManager:all()
    return self._assets.published
end

function AssetManager:count()
    local list = self._assets.published
    return #list
end

-- callback: function(name, asset_or_nil)
function AssetManager:load(name, callback)
    local asset = Asset()
    asset.completionCallback = callback
    self:_beganLoading(name, asset)
    self.client:asset_request(name)
end

function AssetManager:_published(name)
    for i, v in ipairs(self._assets.published) do
        if v:id() == name then
            return v
        end
    end
end

function AssetManager:_loading(name)
    return self._assets.loading[name]
end

function AssetManager:_beganLoading(name, asset)
    self._assets.loading[name] = asset
end

function AssetManager:_finishedLoading(name, asset)
    self._assets.loading[name] = nil
end

function AssetManager:_handleRequest(name, offset, length)
    local asset = self:_published(name)
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
        print("Could not fetch asset " .. name .. " (" .. state ")")
    end
    self:_finishedLoading(name, asset)
end

Asset = class()

function Asset:_init(data)
    self.data = data
    self._id = nil
end

function Asset:read(offset, length)
    if self.data == nil then return nil end
    return string.sub(self.data, offset, offset + length - 1)
end

function Asset:write(data, offset, totalSize)
    if self.data == nil then
        self.data = data
    else
        self.data = self.data .. data
    end
end

function Asset:size()
    if self.data == nil then return 0 end
    return string.len(self.data)
end

function Asset:id(refresh)
    if self._id == nil or refresh then
        local data = self.data or self:read(1, self:size())
        if data == nil then return nil end
        self._id = allonet.asset_generate_identifier(data)
    end
    return self._id
end

Base64Asset = class(Asset)

function Base64Asset:_init(base64)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' -- You will need this for encoding/decoding
    base64 = string.gsub(base64, '[^'..b..'=]', '')
    local data = (base64:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
            return string.char(c)
    end))
    self:super(data)
end



FileAsset = class(Asset)

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


if package.loaded['cairo'] then 
    CairoAsset = class(Asset)

    function CairoAsset:_init(surface)
        self.surface = surface
        self.counter = 0
    end

    function CairoAsset:update(surface)
        surface = surface or self.surface
        local received = ""
        local ret = surface:save_png(function(_, data, len)
            received = received..ffi.string(data, len)
            return 0
        end, nil)
        self.data = received
        print("CairoAsset wrote png stream", ret)
        self.counter = self.counter + 1
        self:id(true)
    end
    Asset.Cairo = CairoAsset
end


AssetView = class(View)

function AssetView:_init(asset, bounds)
    self:super(bounds)
    self._asset = asset
end

function AssetView:_geometry()
    return {
        type = "asset",
        name = self._asset:id()
    }
end

function AssetView:specification()
    local mySpec = tablex.union(ui.View.specification(self), {
        geometry = self:_geometry(),
        grabbable = {
            grabbable = true,
        },
        collider= {
            type= "box",
            width= 1, height= 1, depth= 1
        },
    })
    return mySpec
end

function AssetView:asset(asset)
    if asset == nil then
        return self._asset
    else 
        self._asset = asset
        self:updateComponents({geometry = self:_geometry()})
    end
end
Asset.View = AssetView

Asset.Manager = AssetManager
Asset.Data = Asset
Asset.File = FileAsset
return Asset