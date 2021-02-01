local modules = (...):gsub(".[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local Pose = require(modules .."pose")
local Size = require(modules .."size")

-- defines the pose and size of a view, i e its bounds within the world.
class.Bounds()
-- Bounds{pose=,size=}
-- Bounds(pose, size)
-- Bounds(x, y, z, w, h)
function Bounds:_init(a, b, z, w, h, d)
    if type(a) == "table" then
        if type(b) == table then
            self.pose = a
            self.size = b
        else
            self.pose = a.pose and a.pose or Pose()
            self.size = a.size and a.size or Size()
        end
    else
        self.pose = Pose(a, b, z)
        self.size = Size(w, h, d)
    end
end

function Bounds:copy()
    return Bounds{
        pose=self.pose:copy(),
        size=self.size:copy()
    }
end
function Bounds:rotate(angle, x, y, z)
    self.pose:rotate(angle, x, y, z)
    return self
end

function Bounds:move(x, y, z)
    self.pose:move(x, y, z)
    return self
end

function Bounds:scale(x, y, z)
    self.pose:scale(x, y, z)
    return self
end

return Bounds
