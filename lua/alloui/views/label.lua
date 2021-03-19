--- A text label. 
-- @classmod Label
local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local View = require(modules.."views.view")


class.Label(View)

--- Creates a text label
-- For example:
--
--~~~ lua
-- local l = Label{bounds={0, 0, 0, 1.0, 0.1, 0.001}, color={1.0,0.2,0.4,1}, text="Hello!", halign="left"}
--~~~
--
-- @tparam table o A table including *at least* a Bounds table (the position and size of your Label, i.e. {x, y, z, width, height, depth}). It may also include a number of other optional properties:
-- @tparam string text The Label's text
-- @tparam number lineheight The line height of the Label's text
-- @tparam boolean wrap Whether the Label should insert a line break if the rendered text is wider than its explicit size (defined in its `bounds`)
-- @tparam **"center"**,"top","bottom" halign The alignment of the text within the Labels' bounds
-- @tparam {r,g,b,a} color The r, g, b and a values of the text color, each defined between 0 and 1.
-- @tparam boolean fitToWidth If true, the Label's text size is automatically adjusted to fill the width of its bounds.
-- @usage local l = Label{bounds= ui.Bounds(0, 0, 0,   1.0, 0.07, 0.001), color= {0.4,0.4,0.4,1}, text= "Hello!", halign= "left"}

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

return Label
