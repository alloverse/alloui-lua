--- A Surface is a [View](view) subclass which displays a single texture on a square.
-- @classmod Surface

local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local View = require(modules.."views.view")
local Color = require(modules.."color")

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
    self.uvw = 1.0
    self.uvh = 1.0
end

function Surface:specification()
    local s = self.bounds.size
    local w2 = s.width / 2.0
    local h2 = s.height / 2.0
    local uvw = self.uvw
    local uvh = self.uvh
    local mySpec = tablex.union(View.specification(self), {
        geometry = {
            type = "inline",
                  --   #bl                   #br                  #tl                   #tr
            vertices= {{-w2, -h2, 0.0},      {w2, -h2, 0.0},      {-w2, h2, 0.0},       {w2, h2, 0.0}},
            uvs=      {{0.0, 0.0},           {uvw, 0.0},          {0.0, uvh},           {uvw, uvh}},
            triangles= {{0, 1, 3}, {0, 3, 2}, {1, 0, 2}, {1, 2, 3}},
        },
    })

    table.merge(mySpec, self.customSpecAttributes)
    return mySpec
end

function Surface:setBounds(bounds)
  View.setBounds(self, bounds)
  self:markAsDirty("geometry")
end

function Surface:setCropDimensions(w, h)
  self.uvw = w
  self.uvh = h
  self:markAsDirty("geometry")
end

return Surface
