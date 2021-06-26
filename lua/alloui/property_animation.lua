local modules = (...):gsub(".[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local vec3 = require("modules.vec3")
local mat4 = require("modules.mat4")
require(modules .."random_string")
local Bounds = require(modules .."bounds")

class.PropertyAnimation()
function PropertyAnimation:_init(props)
    self.path = props.path
    assert(self.path, "path must be set")
    self.from = props.from or 0
    self.to = props.to or 1
    self.start_at = props.start_at or 0
    self.duration = props.duration or 1.0
    self.easing = props.easing or "linear"
    self.repeats = props.repeats or false
end

return PropertyAnimation
