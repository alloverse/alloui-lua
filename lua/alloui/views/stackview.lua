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

function StackView:margin(newValue)
    if newValue then
        self._margin = newValue
        self:layout()
    end
    return self._margin
end

function StackView:layout(guard)
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
            v:updateComponents()
        end
        pen:move(offset.x - margin.x, offset.y - margin.y, 0)
    end
    self:updateComponents()
end

return StackView