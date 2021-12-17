------------
-- A suite of standard animations to use in your app.
--

--
-- Example usage:
-- ~~~ lua
--        app:addWristWidget(hand, callupButton, function(ok)
--            if not ok then
--                ui.StandardAnimations.addFailureAnimation(widgetifyButton, 0.03)
--            end
--        end)
-- ~~~
-- @classmod StandardAnimations

local vec3 = require("modules.vec3")
local mat4 = require("modules.mat4")

local standard_animations = {}

function standard_animations.addFailureAnimation(view, width)
    if width == nil then width = 0.1 end
    local origin = view.bounds.pose.transform * vec3.new(0,0,0)
    local x = origin.x
    local stepDuration = 0.1
    view:addPropertyAnimation(ui.PropertyAnimation{
        path= "transform.matrix.translation.x",
        from= x,
        to=   x-width,
        duration= stepDuration,
        easing="quadOut" 
    })
    view:addPropertyAnimation(ui.PropertyAnimation{
        path= "transform.matrix.translation.x",
        from= x-width,
        to=   x+width,
        start_at= view.app:serverTime() + stepDuration*1,
        duration= stepDuration,
        easing="quadInOut" 
    })
    view:addPropertyAnimation(ui.PropertyAnimation{
        path= "transform.matrix.translation.x",
        from= x+width,
        to=   x-width,
        start_at= view.app:serverTime() + stepDuration*2,
        duration= stepDuration,
        easing="quadInOut" 
    })
    view:addPropertyAnimation(ui.PropertyAnimation{
        path= "transform.matrix.translation.x",
        from= x-width,
        to=   x,
        start_at= view.app:serverTime() + stepDuration*3,
        duration= stepDuration,
        easing="quadIn" 
    })
end

return standard_animations
