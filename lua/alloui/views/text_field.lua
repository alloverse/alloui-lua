local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local vec3 = require("modules.vec3")
local mat4 = require("modules.mat4")
local View = require(modules.."views.view")
local Label = require(modules.."views.label")
local Cube = require(modules.."views.cube")
local Bounds = require(modules.."bounds")
local Pose = require(modules.."pose")
local Size = require(modules.."size")



-- A text field, for inputting text. 
class.TextField(View)
-- TextField{bounds=,text=,lineheight=,wrap=,halign=,color={r,g,b,a}}
-- TextField(bounds)
function TextField:_init(o)
    self:super(o.bounds and o.bounds or o)
    local plaqueBounds = Bounds{size=self.bounds.size:copy()}
    self.plaque = Cube(plaqueBounds)
    self.plaque.color = {0.9, 0.9, 0.9, 1.0}
    self:addSubview(self.plaque)

    local labelBounds = plaqueBounds:copy()
    labelBounds:move(0.02, 0, plaqueBounds.size.depth/2+0.001)
    labelBounds.size.height = labelBounds.size.height * 0.7
    o.bounds = labelBounds
    o.halign = o.halign and o.halign or "left"
    o.color = o.color and o.color or {0, 0, 0, 1}
    self.label = Label(o)
    self:addSubview(self.label)

    self:layout()
end

function TextField:onInteraction(inter, body, sender)
    if body[1] == "focus" then
        self:setFocused(true)
    elseif body[1] == "defocus" then
        self:setFocused(false)
    end
end

function TextField:setFocused(newFocused)
    self.isFocused = newFocused
    self:layout()
end

function TextField:specification()
    local s = self.bounds.size
    local mySpec = tablex.union(View.specification(self), {
        focus = {
            type= "key"
        },
        collider= {
            type= "box",
            width= s.width, height= s.height, depth= s.depth
        }
    })
    return mySpec
end

function TextField:layout()
    mat4.identity(self.transform)
    
    mat4.scale(self.transform, self.transform, vec3(1, 1, self.isFocused and 1.0 or 0.1))
    if not self.isFocused then
        mat4.translate(self.transform, self.transform, vec3(0, 0, -self.bounds.size.depth*2))
    end
    self:setTransform(self.transform)
end

return TextField
