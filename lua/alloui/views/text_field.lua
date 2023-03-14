--- A text field, used for inputting text.
--
-- Set `onReturn` to define a function that gets called when the enter key is pressed (while the text field is focused):
--
--~~~ lua 
-- my_textfield.onReturn = function()
-- -- do stuff
--end
--~~~
--
-- Set `onChange` to define a function that gets called when the contents of the text field have changed:
--
--~~~ lua 
-- my_textfield.onChange = function()
-- -- do stuff
--end
--~~~
--
-- Set `onLostFocus` to define a function that gets called when the text field loses focus:
--
--~~~ lua 
-- my_textfield.onLostFocus = function()
-- -- do stuff
--end
--~~~
-- @classmod TextField

local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local vec3 = require("modules.vec3")
local mat4 = require("modules.mat4")
local View = require(modules.."views.view")
local Label = require(modules.."views.label")
local Cube = require(modules.."views.cube")
local FrameView = require(modules.."views.frameview")
local Bounds = require(modules.."bounds")
local Pose = require(modules.."pose")
local Size = require(modules.."size")
local Color = require(modules.."color")

local PLACEHOLDER = "Placeholder"

class.TextField(View)

---
--
--~~~ lua
-- local textfield = TextField(o)
--~~~
--
--For convenience, you may also set some or all of the TextField's properties within the constructor, i.e.:
--~~~ lua
-- local textfield = TextField{bounds=Bounds(0, 0, 0, 1.0, 0.1, 0.001), color={1.0,0.2,0.4,1}, halign="center"}
--~~~
--
-- @tparam table o A table including *at least* a Bounds component.
function TextField:_init(o)
    self:super(o.bounds and o.bounds or o)

    self.frameModel = app:_getInternalAsset("models/textfield.glb")
    self.frame = ModelView(Bounds.unit(), self.frameModel)
    self:addSubview(self.frame)
    

    local labelBounds = self.bounds:copy():moveToOrigin()
    labelBounds:move(0.02, 0, labelBounds.size.depth * 0.1)
    labelBounds.size.height = labelBounds.size.height * 0.7
    o.bounds = labelBounds
    o.halign = o.halign and o.halign or "left"
    o.color = o.color and o.color or {0, 0, 0, 1}
    self.label = Label(o)
    self.label:setColor(Color:alloDark())
    self:addSubview(self.label)

    -- whether to insert the return or not. use and return false to do things like submit a form.
    self.onReturn = o.onReturn and o.onReturn or function(field, text) return true end

    -- whether to accept change
    self.onChange = o.onChange and o.onChange or function(field, oldText, newText) return true end

    self.onLostFocus = o.onLostFocus and o.onLostFocus or function(field) end

    self.theme = {
        --            background, frame,      text
        neutral=     {"A9B6D1FF", "A9B6D1FF", "0C2B48FF"},
        highlighted= {"A9B6D1FF", "E7AADAFF", "0C2B48FF"},
        selected=    {"A9B6D1FF", "E7AADAFF", "0C2B48FF"},
    }
    
    self:layout()
    self:_updateLooks()
end

function TextField:onInteraction(inter, body, sender)
    View.onInteraction(self, inter, body, sender)
    if body[1] == "keydown" then
        self:handleKey(body[2])
    elseif body[1] == "keyup" then
        --
    elseif body[1] == "textinput" then
        self:appendText(body[2])
    end
end

function TextField:onFocus(newFocused)
    View.onFocus(self, newFocused)
    self.isFocused = newFocused

    self:_updateLooks()

    if not newFocused then
        self.onLostFocus(self)
    end
    return true
end



function TextField:specification()
    local s = self.bounds.size
    local mySpec = table.merge(View.specification(self), {
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
    self.label.insertionMarker = self.isFocused
    
    self.label:updateComponents({text=self.label:specification().text})

    local bounds = self.bounds
    local scale = bounds.size.height
    self.frame.bounds = bounds:copy():moveToOrigin():scale(scale, scale, -scale)
    local scaledWidth = bounds.size.width/scale
    self.frame:transformNode("left", Pose(0.0, scaledWidth, 0.0))
    self.frame:transformNode("right", Pose(0, scaledWidth, 0))
end

function TextField:_updateLooks()
    
    local current = self.isFocused and self.theme.selected or
                        self.highlighted and self.theme.highlighted or
                        self.theme.neutral
    self.frame:setColorSwap(Color("00FF00FF"), Color(current[1]), 1) -- background
    self.frame:setColorSwap(Color("FF00FFFF"), Color(current[2]), 2) -- frame
    self.label:setColor(Color(current[3]))
end

--- Appends the provided text to the TextField
--
--@tparam string text The text to append
function TextField:appendText(text)
    local newText = self.label.text .. text
    if self.onChange(self, self.label.text, newText) then
        self.label:setText(newText)
    end
end

function TextField:handleKey(code)
    local newText = self.label.text
    if code == "backspace" then
        newText = newText:sub(1, -2)
    elseif code == "return" or code == "enter" then
        if self.onReturn(self, self.label.text) then
            newText = newText .. "\n"
        end
    end

    if newText ~= self.label.text and self.onChange(self, self.label.text, newText) then
        self.label:setText(newText)
    end
end

return TextField
