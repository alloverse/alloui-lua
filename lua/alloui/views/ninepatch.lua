--- A ninepatch is a [View](view) subclass which displays a 9patch texture on a square.
-- @classmod Ninepatch

local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local View = require(modules.."views.view")
local Color = require(modules.."color")

class.Ninepatch(View)
---
--
--~~~ lua
-- surface = Surface(bounds, texture, inset)
--~~~
--
-- @tparam [Bounds](bounds) bounds The Surface's bounds.
-- @tparam number inset The size of the border of the surface
-- @tparam [Texture](texture) An asset with the 9patch image texture to use
-- @tparam number textureInset The number of pixels to inset from each side in the texture image
function Ninepatch:_init(bounds, inset, texture, textureInset)
    self:super(bounds)
    self.asset = nil
    self.inset = inset
    self.textureInset = textureInset
    self.texturePixelWidth = 0
    self.texturePixelHeight = 0

    self:setTexture(texture)
end

function Ninepatch:setTexture(texture)
    View.setTexture(self, texture)
    self.texturePixelWidth, self.texturePixelHeight = self.material.texture:getImageWidthHeight()
end

function Ninepatch:specification()
    if not self.app then 
        return View.specification(self)
    end
    if not self.asset then
        self.asset = Asset.Geometry.make9PatchGeometry(
            self.bounds.size.width, 
            self.bounds.size.height,
            self.inset, self.inset,
            self.texturePixelWidth,
            self.texturePixelHeight,
            self.textureInset,
            self.textureInset
        )
        self.app.assetManager:add(self.asset, false)
    end

    local mySpec = table.merge(View.specification(self), {
        geometry = {
            type = "asset",
            name = self.asset:id()
        },
    })

    table.merge(mySpec, self.customSpecAttributes)
    return mySpec
end

function Ninepatch:setBounds(bounds)
  View.setBounds(self, bounds)
  self.asset = nil

  self:markAsDirty("geometry")
end

return Ninepatch
