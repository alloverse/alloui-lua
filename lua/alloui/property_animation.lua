------------
-- PropertyAnimation describes the animation of a field in a component in an entity.
-- It can be any field that is numeric, 4x4 matrix, vec3 or a rotation (as an angle-axis as four numbers).
--
-- Use [View:addPropertyAnimation](View#viewaddpropertyanimation-anim) to apply and
-- activate the animation.
--
-- Example usage:
-- ~~~ lua
--       self.logo:addPropertyAnimation(ui.PropertyAnimation{
--          path= "transform.matrix.rotation.y",
--          start_at = self.app:serverTime() + 1.0,
--          from= -0.2,
--          to=   0.2,
--          duration = 2.0,
--          repeats= true,
--          autoreverses= true,
--          easing= "elasticOut",
--        })
-- ~~~
-- @classmod PropertyAnimation

local modules = (...):gsub(".[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local vec3 = require("modules.vec3")
local mat4 = require("modules.mat4")
require(modules .."random_string")
local Bounds = require(modules .."bounds")

class.PropertyAnimation()
-- Construct a PropertyAnimation with the 
-- @tparam table o A table with at least `path`. Can also contain `from`, `to`, `start_at`, `duration`, `easing`, `repeats` and/or `autoreverses`.
function PropertyAnimation:_init(o)
    self.path = o.path
    assert(self.path, "path must be set")
    self.from = o.from or 0
    self.to = o.to or 1
    self.start_at = o.start_at or 0
    self.duration = o.duration or 1.0
    self.easing = o.easing or "linear"
    self.repeats = o.repeats or false
    self.autoreverses = o.autoreverses or false
end

--- You describe the property to be animated by setting the path to the _key path_ of the property.
-- For example, to change the alpha field (fourth field) of the color property of the `material` component, 
-- use the path `material.color.3` (0-indexed).
--
-- Matrices also have some magical computed properties. You can access `rotation`, `scale` and `translation`
-- of a matrix to directly set that attribute of the matrix. You can also dive into the specific setting for
-- the x, y or z axies of each of those. For example, to rotate around y, you can animate
-- `transform.matrix.rotation.y`. In that case, the "from" and "to" values can be regular numbers.
--@tparam string path The keypath to the property to animate
function PropertyAnimation:setPath(path)
    self.path = path
end

--- The value to animate from. Can be a number, matrix (list of 16 numbers), vector (list of 3 numbers) or rotation
-- (list of 4 numbers: angle, and the x y z of the axis). It MUST be the same kind of value as the property we're
-- animating (see [setPath](#propertyanimationsetpath-path)).
--@tparam number|mat4|vec3|{a,ax,ay,az} from Value to animate from
function PropertyAnimation:setFrom(from)
    self.from = from
end

--- The value to animate to. See `setFrom`.
--@tparam number|mat4|vec3|{a,ax,ay,az} to Value to animate to
function PropertyAnimation:setTo(to)
    self.to = to
end

--- The time at which to start the animation. Use App:serverTime() to get the current time, and use offsets
-- from that time to get time in the future. To start an animation in four seconds, use `myview.app:serverTime()+4`.
--@tparam number start_at Server time at which to start the animation
function PropertyAnimation:setStartAt(start_at)
    self.start_at = start_at
end

--- The number of seconds to animate for, in seconds.
-- After the time start_at + duration has elapsed, the animation is automatically removed, unless it's
-- a repeating animation.
--@tparam number duration Duration of animation in seconds
function PropertyAnimation:setDuration(duration)
    self.duration = duration
end

--- Set the easing curve used to animate along. The default is `linear`, which means going in a straight line
-- from `from` to `to`. This usually looks very stiff and robotic, and is discouraged. Use one of these
-- easing algorithms instead:
-- 
-- * linear
-- * quadInOut
-- * quadIn
-- * quadOut
-- * bounceInOut
-- * bounceIn
-- * bounceOut
-- * backInOut
-- * backIn
-- * backOut
-- * sineInOut
-- * sineIn
-- * sineOut
-- * cubicInOut
-- * cubicIn
-- * cubicOut
-- * quartInOut
-- * quartIn
-- * quartOut
-- * quintInOut
-- * quintIn
-- * quintOut
-- * elasticInOut
-- * elasticIn
-- * elasticOut
-- * circularInOut
-- * circularIn
-- * circularOut
-- * expInOut
-- * expIn
-- * expOut
--@tparam string easing Name of the easing algorithm to use
function PropertyAnimation:setEasing(easing)
    self.easing = easing
end

--- Whether this animation restarts plays again immediately after finishing.
-- Repeating animations are never removed automatically.
--@tparam bool repeats Whether to repeat
function PropertyAnimation:setRepeats(repeats)
    self.repeats = repeats
end

--- For repeating animations: Whether to play this animation back in reverse
-- after each time it has been played front-to-back.
--@tparam bool autoreverses Whether to autoreverse
function PropertyAnimation:setAutoreverses(autoreverses)
    self.autoreverses = autoreverses
end

--- Asks server to stop the animation and remove it 
function PropertyAnimation:removeFromView(callback)
    if self.id == nil or self.view == nil then
        print("Not removing animation", self, "because it isn't assigned to a view")
        return
    end
    self.view.app.client:sendInteraction({
        sender_entity_id = self.view.entity.id,
        receiver_entity_id = "place",
        body = {
            "remove_property_animation",
            self.id
        }
    }, function(response, body)
        if body[2] ~= "ok" then
            local errorMessage = body[3]
            print("Failed to remove animation for "..self.path.." on "..self.view.entity.id..": "..errorMessage)
            return
        end
        self.id = nil
        self.view = nil
        if callback then callback() end
    end)
end

return PropertyAnimation
