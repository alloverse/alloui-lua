local class = require('pl.class')
local Asset = require ('alloui.asset.asset')

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
