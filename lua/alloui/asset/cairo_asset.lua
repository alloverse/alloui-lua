local class = require('pl.class')
local Asset = require ('alloui.asset.asset')
local ffi = require('ffi')
local ok, cairo = pcall(require, 'cairo')
if ok then 
    CairoAsset = class.CairoAsset(Asset)

    function CairoAsset:_init(surface)
        self.surface = surface
        self.counter = 0
    end

    function CairoAsset:update(surface)
        assert(ffi, "ffi required")
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

    -- If the asset represents a PNG file then return a cairo surface
    function Asset:getCairoSurface()
        assert(ffi, "ffi required")
        local offset = 1
        local surface = cairo.load_png(function (_, data, len)
            local bytes = self:read(offset, len)
            ffi.copy(data, bytes, #bytes)
            offset = offset + #bytes
            if len ~= #bytes then return 10 end -- CAIRO_STATUS_READ_ERROR
            return 0 -- CAIRO_STATUS_SUCCESS
        end, ffi.new("void*"))
        return surface
    end

    return CairoAsset
end
return nil
