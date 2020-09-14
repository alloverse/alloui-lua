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
    self.texture = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsQAAA7EAZUrDhsAAAM6SURBVHhe7Zq9b9NAGIdfJ2lSqlYCNtQVhGBkKOIPQOJjQEgMTBUDYkDqVDb+BqZuwFKpCxJiQRVCZWBKF9S1c4QQXfgKH21omuD3cm+4nBz7fL472z0/Uvq6kXr277n37MZxsLuzOQSPqfHqLZUAXr2lEsCrtxgVcOHSTfayhY3xjVwG6aCuPhkNtbUasBqOzWpWcPxGOFX9AX8jxNTYmQTIwUVIAqJ7sDj+qdkafDsYwOeV6/xdgI/dfVhaf8+2s4rQEiC2YVR4Ed1uoH2IwWXOrL3hW/oiUgm4dvshdDodtp0UXEZVhEpwmSwilAXEtbsqccsCx5+fCeDX4TBVeBESkUZCooA07a6KLEJn1uNII2KqABvBZUQRpsITqssiUoCJdo+Dgj9YvgWt5gysPX/JfjctAUkSMSEAg9Nlx0Z4DE7X85X7d/i7/3EhQpYwFuBq1qOCi6CEqGu/CaK6AY9qeLJVg+89e7OOJAWXcdUNTIDN4Avzc3Dv7g22nZbNrTZ82duDH+Hk2OoG4wIoOJJ21qdhoxusCNBtd1VMijAqwHZwEZTQrAfw90j/P0bEiAAb7a5K1m7ILMDlrMehK0JbQFGCi5AERFUECdC6JVak8EiW46luivJaenS7oOoAXr2lEsCrd1xZPM2qtwK2P31l1VsBq0tnWfVWwKPL51itToL4Q/xU5xtVB/DqLZUAXo8FC031c9n4fgB9QYAnwrKfDBu15OPH4BefvWXbmJ11AG6IIspKfzD9zla3dzie9Xb79TjvxBIgEWXthmkdgMHPP303MdFE5DmgrCL2+5MdgMHxFRWciD0J0h99eFwvhYgTjdExyus8jsQnRAjxgYmi3RQlNjZesW+VkaTghLIAoqgi6Na4anAitQARkpGnCPE7gbThkUwCEJQwG669g/AE5FIEBp8L9/sn3K9OcCKzAMJlN+i2exTGBBA2RZgMThgXgKCEVj2A3pGZZYHB6bkhk+ERKwII6gZEV4SNWRexKoDQWRa2gxNOBBAqIro/f8P6i9GHFtvhEacCEJRAj7jIIlzNuohzAYTYDXkEJ3ITgJCEPIITuQooAsfqnqAOlQBevcVzAQD/ACwg7buhFwAGAAAAAElFTkSuQmCC"
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
            texture= self.texture
        },
    })
    return mySpec
end

-- Set a base64-encoded png texture on a surface.
-- Use e g https://www.base64-image.de/ to convert your image to base64.
-- Please keep this small, as this base64 hack is very resource intensive.
function Surface:setTexture(base64png)
    self.texture = base64png
    if self:isAwake() then
      local geom = self:specification().geometry
      self:updateComponents({
          geometry= geom
      })
    end
end

return Surface