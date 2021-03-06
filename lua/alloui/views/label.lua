--- A text label. 
-- @classmod Label
local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local View = require(modules.."views.view")




class.Label(View)

--- Label{bounds=,text=,lineheight=,wrap=,halign=,color={r,g,b,a}}
-- Label(bounds)
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

function Label:setText(text)
    self.text = text
    if self:isAwake() then
        self:updateComponents(self:specification())
    end
end

return Label
