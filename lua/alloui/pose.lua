--- The "position" of a view. Abstracts a mat4 transformation matrix.
--
-- @classmod Pose

local modules = (...):gsub(".[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local vec3 = require("modules.vec3")
local mat4 = require("modules.mat4")

class.Pose()

---
--~~~ lua
-- pose = Pose() -- Creates a zero pose
--~~~
-- A Pose may also be created the following ways:
--~~~ lua
-- pose = Pose(transform) -- Creates a pose from a transform
-- pose = Pose(x, y, z) -- Create positioned pose
-- pose = Pose(a, x, y, z) -- Create rotated pose
--~~~
function Pose:_init(a, b, c, d)
    if b == nil then
        self.transform = a or mat4.identity()
    elseif d == nil then
        self.transform = mat4.translate(mat4.identity(), mat4.identity(), vec3(a, b, c))
    else
        self.transform = mat4.rotate(mat4.identity(), mat4.identity(), a, vec3(b, c, d))
    end
end

function Pose:__tostring()
    local pos = self.transform * vec3()
    return string.format("<Pose %0.3f, %0.3f, %0.3f>", pos.x, pos.y, pos.z)
end

--- Creates and returns a copy of a given Pose
-- 
-- @treturn [Pose](pose) A copy of the original Pose object.
function Pose:copy()
    return Pose(mat4(self.transform))
end

--- Sets the Pose to {0, 0, 0, 0}.
-- 
-- @treturn [Pose](pose) original Pose, post reset to the identity matrix.
function Pose:identity()
    self.transform = mat4.identity()
    return self
end

--- Sets the Pose to inherit 
-- 
-- @tparam [Pose](pose) other The source Pose to copy.
-- @treturn [Pose](pose) the original Pose, after having been updated.
function Pose:set(other)
    self.transform = mat4(other.transform)
    return self
end

--- Rotates the Pose
-- 
-- @tparam number angle The angle component of the angle/axis rotation (radians).
-- @tparam number x The x component of the axis of rotation.
-- @tparam number y The y component of the axis of rotation.
-- @tparam number z The z component of the axis of rotation.
-- @treturn [Pose](pose) The original Pose, post-rotation.
function Pose:rotate(angle, x, y, z)
    self.transform = mat4.rotate(self.transform, self.transform, angle, vec3(x, y, z))
    return self
end

--- Moves the Pose
-- 
-- @tparam number x The movement along the x axis.
-- @tparam number y The movement along the y axis.
-- @tparam number z The movement along the z axis.
-- @treturn [Pose](pose) The original Pose, post-move.
function Pose:move(x, y, z)
    self.transform = mat4.translate(self.transform, self.transform, vec3(x, y, z))
    return self
end

--- Scales the Pose
-- 
-- @tparam number x The x component of the scale to apply.
-- @tparam number y The y component of the scale to apply.
-- @tparam number z The z component of the scale to apply.
-- @treturn [Pose](pose) The original Pose, post-scale.
function Pose:scale(x, y, z)
    self.transform = mat4.scale(self.transform, self.transform, vec3(x, y, z))
    return self
end

return Pose
