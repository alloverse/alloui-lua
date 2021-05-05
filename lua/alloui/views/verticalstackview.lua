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


class.VerticalStackView(View)
function VerticalStackView:_init(bounds)
    self:super(bounds)

    self._margin = 0.01
end

function VerticalStackView:margin(newValue)
    if newValue then
        self._margin = newValue
        self:layout()
    end
    return self._margin
end

function VerticalStackView:layout()
    if #self.subviews == 0 then return end

    local width = self.bounds.size.width
    local pen = Pose(0, self.bounds.size.height/2, 0)
    for i, v in ipairs(self.subviews) do
        pen:move(0, -v.bounds.size.height/2, 0)
        v.bounds.pose = pen:copy()
        v.bounds.size.width = width
        v:updateComponents()
        pen:move(0, -v.bounds.size.height/2 - self._margin, 0)
    end
end

return VerticalStackView