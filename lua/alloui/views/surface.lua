--- A Surface is a [View](view) subclass which displays a single texture on a square.
-- @classmod Surface

local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local View = require(modules.."views.view")

class.Surface(View)
---
--
--~~~ lua
-- surface = Surface(bounds)
--~~~
--
-- @tparam [Bounds](bounds) bounds The Surface's bounds.
function Surface:_init(bounds)
    self:super(bounds)
    self.texture = nil
    self.color = nil
end

function Surface:specification()
    local s = self.bounds.size
    local w2 = s.width / 2.0
    local h2 = s.height / 2.0
    local mySpec = tablex.union(View.specification(self), {
        geometry = {
            type = "inline",
                  --   #bl                   #br                  #tl                   #tr
            vertices= {{-w2, -h2, 0.0},      {w2, -h2, 0.0},      {-w2, h2, 0.0},       {w2, h2, 0.0}},
            uvs=      {{0.0, 0.0},           {1.0, 0.0},          {0.0, 1.0},           {1.0, 1.0}},
            triangles= {{0, 1, 3}, {0, 3, 2}, {1, 0, 2}, {1, 2, 3}},
        },
    })

    if (self.texture or self.color) and mySpec.material == nil then
        mySpec.material = {}
    end

    if self.texture then
      mySpec.material.texture = self.texture:id()
    end
    if self.color then
      mySpec.material.color = self.color
    end
    return mySpec
end


--- Set the Surface's texture using an Asset.  
-- The `asset` parameter can be either an [Asset](asset) instance or a raw string hash
--
--~~~ lua
-- Surface:setTexture(asset)
--~~~
--
-- @tparam [Asset](asset) asset An instance of an Asset
function Surface:setTexture(asset)
    self.texture = asset
    if self:isAwake() then
      local mat = self:specification().material
      self:updateComponents({
          material= mat
      })
    end
end

--- Set the color of a Surface using a set of rgba values between 0 and 1.
-- E.g. to set the surface to be red and 50% transparent, set this value to `{1, 0, 0, 0.5}`
--
--~~~ lua
-- Surface:setColor(rgba)
--~~~
--
-- @tparam table rgba A table defining a color value with alpha between 0-1.
function Surface:setColor(rgba)
    self.color = rgba
    if self:isAwake() then
      local mat = self:specification().material
      self:updateComponents({
          material= mat
      })
    end
end

function Surface:setBounds(bounds)
  View.setBounds(self, bounds)

  if self:isAwake() then
    local geom = self:specification().geometry
    self:updateComponents({
        geometry= geom
    })
  end

end

return Surface