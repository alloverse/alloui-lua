local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local View = require(modules.."views.view")


-- A Surface is a View subclass which displays a single texture on a square.
-- The texture will later be a reference to an image asset, but for now you specify
-- the texture as a base64-encoded png.
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
      mySpec.material.texture = self.texture
    end
    if self.color then
      mySpec.material.color = self.color
    end
    return mySpec
end

-- Set a base64-encoded png texture on a surface.
-- Use e g https://www.base64-image.de/ to convert your image to base64.
-- Please keep this small, as this base64 hack is very resource intensive.
function Surface:setTexture(base64png)
    self.texture = base64png
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

return Surface