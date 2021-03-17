--- A Surface is a View subclass which displays a single texture on a square.
-- @classmod Surface

local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local View = require(modules.."views.view")

class.Surface(View)
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
        material = {
        },
    })
    if self.texture then
      mySpec.material.texture = self.texture:id()
    end
    if self.color then
      mySpec.material.color = self.color
    end
    if self.hasTransparency then 
      mySpec.material.hasTransparency = self.hasTransparency
    end
    return mySpec
end

--- Set an asset as texture on a surface.
-- The `asset` parameter can be either an `Asset` instance or a raw string hash
-- @tparam Asset asset An instance of an asset
function Surface:setTexture(asset)
    self.texture = asset
    if self:isAwake() then
      local mat = self:specification().material
      self:updateComponents({
          material= mat
      })
    end
end

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