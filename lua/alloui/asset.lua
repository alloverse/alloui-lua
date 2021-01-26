local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local ffi = require('ffi')


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
    table.insert(self._assets.published, asset)
end

function AssetManager:remove(asset)
    for i, v in ipairs(self._assets.published) do
        if v == asset then
            table.remove(self._assets.published, i)
            return;
        end
    end
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
    self.asset = asset
end

function AssetView:specification()
    local mySpec = tablex.union(ui.View.specification(self), {
        geometry = {
            type = "asset",
            name = self.asset:id()
        },
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
Asset.View = AssetView

Asset.Manager = AssetManager
Asset.Data = Asset
Asset.File = FileAsset
return Asset