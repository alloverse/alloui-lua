
--- A FrameView is a [View](view) subclass that draws a border of a given width and color.
-- @classmod FrameView

local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local View = require(modules.."views.view")
local Cube = require(modules.."views.cube")
local Color = require(modules.."color")
local vec3 = require("modules.vec3")
local mat4 = require("modules.mat4")


class.FrameView(View)
---
--
--~~~ lua
-- local frameview = FrameView(o, thickness)
--~~~
--
--For convenience, you may also set some or all of the FrameView's properties within the constructor, i.e.:
--~~~ lua
-- local frameview = FrameView{bounds=Bounds(0, 0, 0, 1.0, 0.1, 0.001), color={1.0,0.2,0.4,1}, position="inside"}
--~~~
--
-- @tparam table o A table including *at least* a Bounds component.
function FrameView:_init(bounds, thickness)
    self:super(bounds)
    local cubeBounds = Bounds{size= bounds.size:copy()}

    -- TODO: Calculate frame position with insetEdges: inside (default) | outside | center       :insetEdges(thickness | -thickness | thickness/2)

    self.top    = self:addSubview(Cube(cubeBounds:copy()))
    self.left   = self:addSubview(Cube(cubeBounds:copy()))
    self.right  = self:addSubview(Cube(cubeBounds:copy()))
    self.bottom = self:addSubview(Cube(cubeBounds:copy()))
    self.thickness = thickness
    self:layout()
end

function FrameView:setColor(color)
    self.top.color = color
    self.left.color = color
    self.right.color = color
    self.bottom.color = color
    return self
end

function FrameView:layout()
    local w2 = self.bounds.size.width / 2
    local h2 = self.bounds.size.height / 2
    local d2 = self.bounds.size.depth / 2
    local t2 = self.thickness/2

    self.top.bounds.size.height = self.thickness
    self.top.bounds:move(0, -h2 + t2, 0)

    self.bottom.bounds.size.height = self.thickness
    self.bottom.bounds:move(0, h2 - t2, 0)

    self.left.bounds.size.width = self.thickness
    self.left.bounds:move(-w2 + t2, 0, 0)

    self.right.bounds.size.width = self.thickness
    self.right.bounds:move(w2 - t2, 0, 0)
end

return FrameView
