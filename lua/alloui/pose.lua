local modules = (...):gsub(".[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local vec3 = require("modules.vec3")
local mat4 = require("modules.mat4")

-- "position" of a view. Abstracts a mat4 transformation matrix.
class.Pose()
-- Pose(): create zero pose
-- Pose(transform): create pose from transform
-- Pose(x, y, z): create positioned pose
-- Pose(a, x, y, z): create rotated pose
function Pose:_init(a, b, c, d)
    if b == nil then
        self.transform = a or mat4.identity()
    elseif d == nil then
        self.transform = mat4.translate(mat4.identity(), mat4.identity(), vec3(a, b, c))
    else
        self.transform = mat4.rotate(mat4.identity(), mat4.identity(), a, vec3(b, c, d))
    end
end

function Pose:copy()
    return Pose(mat4(self.transform))
end

function Pose:rotate(angle, x, y, z)
    self.transform = mat4.rotate(self.transform, self.transform, angle, vec3(x, y, z))
    return self
end

function Pose:move(x, y, z)
    self.transform = mat4.translate(self.transform, self.transform, vec3(x, y, z))
    return self
end

function Pose:scale(x, y, z)
    self.transform = mat4.scale(self.transform, self.transform, vec3(x, y, z))
    return self
end

return Pose
