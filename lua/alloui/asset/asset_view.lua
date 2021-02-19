--- 
-- @classmod AssetView

local class = require('pl.class')
local View = require ('alloui.views.view')
local Asset = require ('asset')

AssetView = class.AssetView(View)
function AssetView:_init(asset, bounds)
    self:super(bounds or ui.Bounds(0, 0, 0,   1, 1, 1))
    self.asset = asset
end
function AssetView:specification()
    local spec = View.specification(self)
    if self.asset then 
        spec.geometry = {
            type = "asset",
            name = self.asset:id(),
        }
    end
    return spec
end
Asset.View = AssetView

function Asset:makeView(bounds)
    return AssetView(self, bounds)
end

if package.loaded['cairo'] then 
    CairoAsset = class.CairoAsset(Asset)

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
