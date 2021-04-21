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


class.GridView(View)
function GridView:_init(bounds)
    self:super(bounds)
end

function GridView:layout()
    if #self.subviews == 0 then return end

    local w2 = self.bounds.size.width/2
    local h2 = self.bounds.size.height/2
    local d2 = self.bounds.size.depth/2

    local firstItem = self.subviews[1]
    local iw = firstItem.bounds.size.width
    local ih = firstItem.bounds.size.height
    local countPerRow = self.bounds.size.width/iw

    local pen = Pose()
    pen:move(-w2 + iw/2, h2 - ih/2, 0)
    for i, v in ipairs(self.subviews) do
        v.bounds.pose = pen:copy()
        pen:move(iw, 0, 0)
        if i % countPerRow == 0 then
            pen:move(-iw*countPerRow, -ih, 0)
        end
    end
end

return GridView