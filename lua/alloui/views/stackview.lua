local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local vec3 = require("modules.vec3")
local mat4 = require("modules.mat4")
local Bounds = require(modules .."bounds")
local Size = require(modules .."size")
local Pose = require(modules .."pose")
local View = require(modules .."views.view")


class.StackView(View)

---
-- A view that stacks its subviews either vertical (default) or horizontally.
-- 
-- The StackView will adjust its size on the (specified) main axis
-- while preserving the size given for the other axis.
-- It will also adjust the size of each subview to fill the other axis while
-- preserving the subview size on the main axis.
-- 
-- You can put StackViews into Stackviews to create rows and columns
--~~~ lua
-- rows = StackView(nil, "v")
-- rows:addSubview(Label{text="Example"})
-- cols = rows:addSubview(StackView(nil, "h"))
-- cols:addSubview(Label{text="Col1"})
-- cols:addSubview(Label{text="Col2"})
-- rows:addSubview(Label{text="The End"})
-- self:addSubview(rows)
-- rows:layout()
--~~~
--@tparam [Bounds](bounds) bounds The StackView's Bounds component
--@tparam string axis The main axis to layout subviews on. "v" (default) or "h"
function StackView:_init(bounds, axis)
    self:super(bounds)
    self._margin = 0.05
    if axis and axis:sub(1, 1) == "h" then
        self.onAxis = vec3(1, 0, 0)
        self.offAxis = vec3(0, 1, 0)
    else
        self.onAxis = vec3(0, 1, 0)
        self.offAxis = vec3(1, 0, 0)
    end
end

---Set the spacing between items
---@tparam newValue number The space between subviews. nil to just return the current value.
---@treturn number The current value
function StackView:margin(newValue)
    if newValue then
        self._margin = newValue
        self:layout()
    end
    return self._margin
end

---Layout the subviews
function StackView:layout()
    if #self.subviews == 0 then return end
    local onAxis = self.onAxis
    local offAxis = self.offAxis

    local margin = vec3(self._margin, self._margin) * onAxis
    local offAxisSize = vec3(self.bounds.size.width, self.bounds.size.height, 0) * offAxis
    local pen = Pose(0, 0, 0)
    -- set y positions
    for i, v in ipairs(self.subviews) do
        local size = vec3(v.bounds.size.width, v.bounds.size.height, 0) * onAxis + offAxisSize
        local offset = -(size * onAxis) / 2
        pen:move(offset.x, offset.y, 0)
        v.bounds.pose = pen:copy()
        v.bounds.size.width = size.x
        v.bounds.size.height = size.y
        pen:move(offset.x - margin.x, offset.y - margin.y, 0)
    end
    pen:move(margin.x, margin.y, 0)
    
    -- calculate new stack height
    local height = -((pen.transform * vec3()) * onAxis) + offAxisSize
    self.bounds.size.width = height.x
    self.bounds.size.height = height.y
    
    -- Offset all subviews as all positions are from center. Commit final sizes
    pen = Pose((height * onAxis).x / 2, (height * onAxis).y / 2, 0)
    for i, v in ipairs(self.subviews) do
        local size = vec3(v.bounds.size.width, v.bounds.size.height, 0) * onAxis + offAxisSize
        local offset = -(size * onAxis) / 2
        pen:move(offset.x, offset.y, 0)
        v.bounds.pose = pen:copy()
        v.bounds.size.width = size.x
        v.bounds.size.height = size.y
        if v.layout then
            v:layout()
            v:markAsDirty()
        end
        pen:move(offset.x - margin.x, offset.y - margin.y, 0)
    end
    self:markAsDirty()
end

return StackView