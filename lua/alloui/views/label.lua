--- A label, used to display text in Alloverse
-- @classmod Label
local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local View = require(modules.."views.view")


class.Label(View)

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
-- @tparam table o A table including *at least* a Bounds component. It may also include a number of other optional properties: text, lineheight, wrap, halign, color and fitToWidth.
function Label:_init(o)
    local bounds = o.bounds and o.bounds or o
    self:super(bounds)
    self.text = o.text and o.text or ""
    self.lineheight = o.lineheight and o.lineheight or bounds.size.height
    self.wrap = o.wrap and o.wrap or bounds.size.width
    self.halign = o.halign and o.halign or "center"
    self.color = o.color and o.color or {1,1,1,1}
    self.fitToWidth = o.fitToWidth and o.fitToWidth or 0
end

function Label:specification()
    local mySpec = tablex.union(View.specification(self), {
        text = {
            string = self.text,
            height = self.lineheight,
            wrap = self.wrap,
            halign = self.halign,
            fitToWidth = self.fitToWidth
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

--- Sets the Label's line height
-- @tparam number lineheight The Label's line height (in meters)
function Label:setLineheight(lineheight)
  self.lineheight = lineheight
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
-- @tparam number desiredWidth The desired width with which to constrain the label text.
function Label:setFitToWidth(desiredWidth)
  self.fitToWidth = desiredWidth
  if self:isAwake() then
      self:updateComponents(self:specification())
  end
end

return Label
