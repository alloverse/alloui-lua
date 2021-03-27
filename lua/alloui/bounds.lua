--- A component that defines the pose and size of a [View](view), i.e. its bounds within the world.
-- Note that any changes made to the Bounds using the methods below won't be applied (and thus visible in the world) until [View:setBounds()](/view#setBounds) is been run.
--
-- @classmod Bounds

local modules = (...):gsub(".[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local Pose = require(modules .."pose")
local Size = require(modules .."size")

class.Bounds()

---
--~~~ lua
-- bounds = Bounds(a, b, c, w, h, d)
--~~~
-- For convenience, a Bounds may also be created using [Pose](pose) and [Size](size) objects:
--~~~ lua
-- bounds = Bounds{pose=,size=}
-- bounds = Bounds(pose, size)
--~~~
--
-- @tparam number a The View's x position in the world
-- @tparam number b The View's y position in the world
-- @tparam number c The View's z position in the world
-- @tparam number w The View's width
-- @tparam number h The View's height
-- @tparam number d The View's depth
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

function Bounds:__tostring()
    return "<Bounds "..tostring(self.size).." @ "..tostring(self.pose)..">"
end

--- Makes a copy of a given Bounds object
--  
--@treturn [Bounds](bounds) A copy of the given Bounds.
function Bounds:copy()
    return Bounds{
        pose=self.pose:copy(),
        size=self.size:copy()
    }
end

--- Sets the Bounds' [Pose](pose) component to {0, 0, 0}
-- @treturn [Bounds](bounds) The updated Bounds object.
function Bounds:moveToOrigin()
    self.pose:identity()
    return self
end

--- Rotates the Bounds around an axis.
-- @tparam number angle The amount to rotate the coordinate system by, in radians.
-- @tparam number x The x component of the axis of rotation.
-- @tparam number y The y component of the axis of rotation.
-- @tparam number z The z component of the axis of rotation.
-- @treturn [Bounds](bounds) The updated Bounds object.
function Bounds:rotate(angle, x, y, z)
    self.pose:rotate(angle, x, y, z)
    return self
end

--- Moves the Bounds.
-- @tparam number x The movement along the x axis.
-- @tparam number y The movement along the y axis.
-- @tparam number z The movement along the z axis.
-- @treturn [Bounds](bounds) The updated Bounds object.
function Bounds:move(x, y, z)
    self.pose:move(x, y, z)
    return self
end

--- Scales the Bounds.
-- @tparam number x The scaling along the x axis.
-- @tparam number y The scaling along the y axis.
-- @tparam number z The scaling along the z axis.
-- @treturn [Bounds](bounds) The updated Bounds object.
function Bounds:scale(x, y, z)
    self.pose:scale(x, y, z)
    return self
end

--- Shrinks the Bounds by the given parameters.
-- 
-- @tparam number w The reduction of the component's width.
-- @tparam number h The reduction of the component's height.
-- @tparam number d The reduction of the component's depth.
-- @treturn [Bounds](bounds) The updated Bounds object.
function Bounds:inset(w, h, d)
    self.size:inset(w, h, d)
    return self
end

function Bounds:insetEdges(left, right, top, bottom, front, back)
    self.size:inset(left+right, top+bottom, front+back)
    self.pose:move(left/2-right/2, top/2-bottom/2, front/2-back/2)
end

function Bounds:extendEdges(left, right, top, bottom, front, back)
    self:insetEdges(-left, -right, -top, -bottom, -front, -back)
end

return Bounds
