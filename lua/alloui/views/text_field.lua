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
local Bounds = require(modules.."bounds")
local Pose = require(modules.."pose")
local Size = require(modules.."size")


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
    local plaqueBounds = Bounds{size=self.bounds.size:copy()}
    self.plaque = Cube(plaqueBounds)
    self.plaque.color = {0.9, 0.9, 0.9, 1.0}
    self:addSubview(self.plaque)

    local borderBounds = Bounds{size=self.bounds.size:copy()}:scale(1.05, 1.05, 0.95)
    self.border = Cube(borderBounds)
    self.border.color = {0.4, 0.4, 0.4, 1.0}
    self:addSubview(self.border)

    local labelBounds = plaqueBounds:copy()
    labelBounds:move(0.02, 0, plaqueBounds.size.depth/2+0.001)
    labelBounds.size.height = labelBounds.size.height * 0.7
    o.bounds = labelBounds
    o.halign = o.halign and o.halign or "left"
    o.color = o.color and o.color or {0, 0, 0, 1}
    self.label = Label(o)
    self:addSubview(self.label)

    -- whether to insert the return or not. use and return false to do things like submit a form.
    self.onReturn = o.onReturn and o.onReturn or function(field, text) return true end

    -- whether to accept change
    self.onChange = o.onChange and o.onChange or function(field, oldText, newText) return true end

    self.onLostFocus = o.onLostFocus and o.onLostFocus or function(field) end
    
    self:layout()
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
    self:layout()
    if not newFocused then
        self.onLostFocus(self)
    end
    return true
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
    self.label.insertionMarker = self.isFocused
    self.label:updateComponents({text=self.label:specification().text})
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
