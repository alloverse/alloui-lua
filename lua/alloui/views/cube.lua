--- A simple cube. Commonly used as a placeholder asset or marker.
-- @classmod Cube
local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."

local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local vec3 = require("modules.vec3")
local mat4 = require("modules.mat4")

local View = require(modules.."views.view")
local Bounds = require(modules.."bounds")

class.Cube(View)

---
--
--~~~ lua
-- cube = Cube(bounds)
--~~~
--
-- @tparam [Bounds](bounds) bounds The Cube's initial bounds.
function Cube:_init(bounds)
    self:super(bounds)

    self.color = {0.9, 0.4, 0.3, 1.0}
end

function Cube:specification()
    local s = self.bounds.size
    local w2 = s.width / 2.0
    local h2 = s.height / 2.0
    local d2 = s.depth / 2.0
    local mySpec = tablex.union(View.specification(self), {
        geometry = {
            type = "inline",
                  --   #fbl                #fbr               #ftl                #ftr             #rbl                  #rbr                 #rtl                  #rtr
            vertices= {{-w2, -h2, d2},     {w2, -h2, d2},     {-w2, h2, d2},      {w2, h2, d2},    {-w2, -h2, -d2},      {w2, -h2, -d2},      {-w2, h2, -d2},       {w2, h2, -d2}},
            uvs=      {{0.0, 0.0},         {1.0, 0.0},        {0.0, 1.0},         {1.0, 1.0},      {0.0, 0.0},           {1.0, 0.0},          {0.0, 1.0},           {1.0, 1.0}   },
            triangles= {
              {0, 1, 2}, {1, 3, 2}, -- front
              {2, 3, 6}, {3, 7, 6}, -- top
              {1, 7, 3}, {5, 7, 1}, -- right
              {5, 1, 0}, {4, 5, 0}, -- bottom
              {4, 0, 2}, {4, 2, 6}, -- left
              {4, 6, 5}, {5, 6, 7}, -- read
            },
        },
        material = {
            color = self.color
        },
    })

    return mySpec
end

--- Sets the Cube's color
-- @tparam table rgba The r, g, b and a values of the text color, each defined between 0 and 1. For example, {1, 0.5, 0, 1}
function Cube:setColor(rgba)
    self.color = rgba
    if self:isAwake() then
      local mat = self:specification().material
      self:updateComponents({
          material= mat
      })
    end
end

return Cube
