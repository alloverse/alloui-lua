--- A label, used to display text in Alloverse
-- @classmod Label
local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local View = require(modules.."views.view")


class.Label(Surface)

---
--
--~~~ lua
-- --Creates a Label, at origo, that is 1m wide, 20cm tall and 1cm deep
-- local l = Label{bounds=Bounds(0, 0, 0, 1, 0.2, 0.01)}
--  
-- --For convenience, you may also set some or all of the Label's properties within the constructor, i.e.:
-- local l = Label{bounds=Bounds(0, 0, 0, 1.0, 0.1, 0.001), color={1.0,0.2,0.4,1}, text="Hello!", halign="left"}
--~~~
--
-- Note: The font size of the text is, by default, derived from the height of the Label.
-- 
-- @tparam table o A table including *at least* a Bounds component. It may also include a number of other optional properties: text, wrap, halign, color and fitToWidth.
function Label:_init(o)
    o = o or Bounds(0,0,0,1,0.1, 0.001)
    local bounds = o.bounds and o.bounds or o
    self:super(bounds)
    self.text = o.text or ""
    self.width = bounds.size.width
    self.height = bounds.size.height
    self.wrap = o.wrap or false
    self.halign = o.halign or "center"
    self.color = o.color or {1,1,1,1}
    self.fitToWidth = o.fitToWidth or false
end

function Label:specification()
    local mySpec = table.merge(View.specification(self), {
        text = {
            string = self.text,
            wrap = self.wrap,
            halign = self.halign,
            fitToWidth = self.fitToWidth,
            width = self.width,
            height = self.height
        },
        material = {
          color = self.color
        }
    })
    if self.insertionMarker then
        mySpec.text.insertionMarker = true
    end
    return mySpec
end

--- Sets the Label's text
-- @tparam string text The text the Label should display
function Label:setText(text)
    self.text = text
    if self:isAwake() then
        self:updateComponents(self:specification())
    end
end

--- Sets the Label's horizontal wrap attribute
-- @tparam boolean wrap Whether the Label should line break when reaching the Label's bounds' (`true`) or be allowed to overflow outside the component (`false`)
function Label:setWrap(wrap)
  self.wrap = wrap
  if self:isAwake() then
      self:updateComponents(self:specification())
  end
end

--- Sets the Label's horizontal align attribute
-- @tparam **"center"**,"top","bottom" halign The alignment of the text within the Labels' bounds
function Label:setHalign(halign)
  self.halign = halign
  if self:isAwake() then
      self:updateComponents(self:specification())
  end
end

--- Sets the Label's text color
-- @tparam {r,g,b,a} color The r, g, b and a values of the text color, each defined between 0 and 1.
function Label:setColor(color)
  self.color = color
  if self:isAwake() then
      self:updateComponents(self:specification())
  end
end

--- Sets the Label's fitToWidth attribute
-- Note: If true, the `wrap` attribute is made irrelevant.
-- @tparam number desiredWidth The desired width with which to constrain the label text.
function Label:setFitToWidth(fitToWidth)
  self.fitToWidth = fitToWidth
  if self:isAwake() then
      self:updateComponents(self:specification())
  end
end

return Label
