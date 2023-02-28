--- A button that can be poked/clicked to perform an action.
-- 
-- Every button has a Label. Use [label:setText(...)](Label#labelsettext-text) to set it:
--~~~ lua
-- my_button.label:setText("this is my button")
--~~~
-- 
-- Set `onActivated` to a function you'd like to be called when the button is pressed:
--
--~~~ lua
-- my_button.onActivated = function()
--  -- do something...
-- end
--~~~
--
-- You can also set the button's default, highlighted and activated texture (see [Surface](Surface) documentation for image format caveats).
-- Or if you just want a colored button, you can set its color.
-- Set either color or texture to nil to remove that attribute.
-- @classmod Button

local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local vec3 = require("modules.vec3")
local mat4 = require("modules.mat4")
local View = require(modules.."views.view")
local ModelView = require(modules.."views.modelview")
local Label = require(modules.."views.label")
local Bounds = require(modules.."bounds")
local Color = require(modules.."color")

class.Button(View)

---
--~~~ lua
-- my_button = Button(bounds)
--~~~
-- @tparam [Bounds](bounds) bounds The button's initial bounds.
-- @tparam string text The button's initial text
function Button:_init(bounds, text)
    -- backwards compat: instantiate CubeButton if user asks for a plain unstyled Button
    if getmetatable(self) == Button then
        setmetatable(self, CubeButton)
        return CubeButton._init(self, bounds, text)
    end

    self:super(bounds or Bounds(0,0,0, 0.5, 0.25, 0.1))
    self.selected = false
    self.highlighted = false
    self.onActivated = nil
    self:setPointable(true)

    self.color = Color.alloDarkPink()
    self.defaultTexture = nil
    self.activatedTexture = nil
    self.highlightTexture = nil

    self.label = Label()
    if text then self.label:setText(text) end
    self.label.color = Color.alloWhite()
    self:addSubview(self.label)
end

function Button:awake()
    View.awake(self)
    self._downSound = self.app:_getInternalAsset("sounds/soft-down.ogg")
    self._upSound = self.app:_getInternalAsset("sounds/soft-up.ogg")
end

function Button:didMoveToSuperview(newSuper)
    self:layout()
    self:_updateLooks()
end

function Button:layout()
    self.label.bounds = Bounds(
        0, 0, self.bounds.size.depth / 2 +0.008,
        self.bounds.size.width*0.9, self.bounds.size.height*0.7, 0.001
    )
end

function Button:updateComponents()
    View.updateComponents(self)
    self.label:updateComponents()
end

function Button:onInteraction(inter, body, sender)
    View.onInteraction(self, inter, body, sender)
    if body[1] == "point" then
        self:setHighlighted(true)
    elseif body[1] == "point-exit" then
        self:setHighlighted(false)
    elseif body[1] == "poke" then
        local newSelected = body[2]
        if newSelected and not self.selected then
            self:playSound(self._downSound)
        end
        self:setSelected(newSelected)

        if newSelected == false and self.highlighted == true then
            self:playSound(self._upSound)
            self:activate(sender)
        end
    end
end

function Button:setHighlighted(highlighted)
    if highlighted == self.highlighted then return end
    self.highlighted = highlighted
    self:_updateLooks()
end

function Button:setSelected(selected)
    if selected == self.selected then return end
    self.selected = selected
    self:_updateLooks()
end

function Button:_updateLooks()
    -- compress button when pressed
    if self.selected and self.highlighted then

    else

    end

    self:markAsDirty()
end

function Button:_effectiveColor()
    if self.color == nil then return nil end
    if self.selected then
        return {self.color[1]*0.6, self.color[2]*0.6, self.color[3]*0.6, 1.0}
    elseif self.highlighted then
        return {self.color[1]*0.8, self.color[2]*0.8, self.color[3]*0.8, 1.0}
    end
    return self.color
end

function Button:activate(byEntity)
    if self.onActivated then
        self.onActivated(byEntity)
    end
end

function Button:setDefaultTexture(t)
    self.defaultTexture = t
    self:setTexture(t)
end

function Button:setHighlightTexture(t)
    self.highlightTexture = t
end

function Button:setActivatedTexture(t)
    self.activatedTexture = t
end

--- Sets the texture of the button
-- Set to nil to remove the attribute.
-- @tparam [Asset](Asset) asset The texture asset
function Button:setTexture(asset)
    self.defaultTexture = asset
    self.color = {1, 1, 1, 1}
    self:_updateLooks()
end

--- Sets the color of the button
-- Set to nil to remove the attribute.
-- @tparam table rgba A table with the desired color's r, g, b and alpha values between 0-1, e.g. `{0.8, 0.4, 0.8, 0.5}`
function Button:setColor(rgba)
    self.color = rgba
    self:_updateLooks()
end


-----
class.CubeButton(Button)
Button.Cube = CubeButton

function CubeButton:_init(bounds, text)
    Button._init(self, bounds, text)
    self.cube = self:addSubview(Cube(self.bounds:copy():moveToOrigin()))
    self.cube.color = self.color
    self:layout()
end

function CubeButton:layout()
    Button.layout(self)
    self.cube.bounds = Bounds(
        0, 0, 0,
        self.bounds.size.width, self.bounds.size.height, self.bounds.size.depth
    )
end

function CubeButton:_updateLooks()
    if self.selected and self.highlighted then
        if self.activatedTexture then self.cube.texture = self.activatedTexture end
    elseif self.highlighted then
        if self.highlightTexture then self.cube.texture = self.highlightTexture end
    else
        if self.defaultTexture then self.cube.texture = self.defaultTexture end
    end

    self.cube.color = self:_effectiveColor()
    self.cube:markAsDirty()
end

function CubeButton:updateComponents()
    Button.updateComponents(self)
    self.cube:updateComponents()
end


----
class.MeshButton(Button)
Button.Mesh = MeshButton

function MeshButton:_init(bounds, model)
    self.model = model or app:_getInternalAsset("models/button.glb")
    self.mesh = ModelView(Bounds.unit(), self.model)

    -- this calls self:setBounds so we need to set the above before calling super
    self:super(bounds)

    self:addSubview(self.mesh)
    self.secondary = false
    self.theme = {
        --            background, frame,      text
        neutral=     {"A9B6D1FF", "A9B6D1FF", "0C2B48FF"},
        highlighted= {"A9B6D1FF", "E7AADAFF", "0C2B48FF"},
        selected=    {"A9B6D1FF", "E7AADAFF", "E7AADAFF"},
        secondary=   {"C8D0E0FF", "C8D0E0FF", "0C2B48FF"},
    }
    self:layout()
end

function MeshButton:setSecondary(sec)
    if sec == self.secondary then return end
    self.secondary = sec
    self:_updateLooks()
end

function MeshButton:_updateLooks()
    Button._updateLooks(self)
    
    local current = self.selected and self.theme.selected or
                        self.highlighted and self.theme.highlighted or
                        self.secondary and self.theme.secondary or
                        self.theme.neutral
    self.mesh:setColorSwap(Color("00FF00FF"), Color(current[1]), 1) -- background
    self.mesh:setColorSwap(Color("FF00FFFF"), Color(current[2]), 2) -- frame
    self.label:setColor(Color(current[3]))
end


function MeshButton:setBounds(bounds)
    Button.setBounds(self, bounds)
    local scale = bounds.size.height
    self.mesh.bounds = bounds:copy():moveToOrigin():scale(scale, scale, scale*2)
    local scaledWidth = bounds.size.width/scale
    self.mesh:transformNode("left", Pose(0.0, scaledWidth, 0.0))
    self.mesh:transformNode("right", Pose(0, scaledWidth, 0))
end



return Button
