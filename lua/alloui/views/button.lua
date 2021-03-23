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
local Label = require(modules.."views.label")
local Bounds = require(modules.."bounds")

class.Button(View)

---
--~~~ lua
-- my_button = Button(bounds)
--~~~
-- @tparam [Bounds](bounds) bounds The button's initial bounds.
function Button:_init(bounds)
    self:super(bounds)
    self.selected = false
    self.highlighted = false
    self.onActivated = nil

    self.label = Label(Bounds(0, 0, bounds.size.depth/2+0.01,   bounds.size.width*0.9, bounds.size.height*0.7, 0.01))
    self.color = {0.9, 0.4, 0.3, 1.0}
    self:addSubview(self.label)
end

function Button:specification()
    local s = self.bounds.size
    local w2 = s.width / 2.0
    local h2 = s.height / 2.0
    local d2 = s.depth / 2.0
    local mySpec = tablex.union(View.specification(self), {
        geometry = {
            type = "inline",
                  --   #fbl                #fbr               #ftl                #ftr             #rbl                  #rbr                 #rtl                  #rtr
            vertices= {{-w2, -h2, d2},     {w2, -h2, d2},     {-w2, h2, d2},      {w2, h2, d2},    {-w2, -h2, -d2},      {w2, -h2, -d2},      {-w2, h2, -d2},       {w2, h2, -d2}},
            uvs=      {{0.0, 0.0},         {1.0, 0.0},        {0.0, 1.0},         {1.0, 1.0},      {0.0, 0.0},           {1.0, 0.0},          {0.0, 1.0},           {1.0, 1.0}   },
            triangles= {
              {0, 1, 2}, {1, 3, 2}, -- front
              {2, 3, 6}, {3, 7, 6}, -- top
              {1, 7, 3}, {5, 7, 1}, -- right
              {5, 1, 0}, {4, 5, 0}, -- bottom
              {4, 0, 2}, {4, 2, 6}, -- left
              {1, 0, 2}, {1, 2, 3}, -- rear
            },
        },
        material = {
        },
        collider= {
            type= "box",
            width= s.width, height= s.height, depth= s.depth
        }
    })

    if self.texture then
      mySpec.material.texture = self.texture:id()
    end
    if self.color then
      mySpec.material.color = self:_effectiveColor()
    end
    return mySpec
end

function Button:onInteraction(inter, body, sender)
    View.onInteraction(self, inter, body, sender)
    if body[1] == "point" then
        self:setHighlighted(true)
    elseif body[1] == "point-exit" then
        self:setHighlighted(false)
    elseif body[1] == "poke" then
        self:setSelected(body[2])

        if self.selected == false and self.highlighted == true then
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
  mat4.scale(self.transform, mat4.identity(), vec3(1, 1, (self.selected and self.highlighted) and 0.01 or 1.0))

  if self.selected and self.highlighted then
    if self.activatedTexture then self.texture = self.activatedTexture end
  elseif self.highlighted then
      if self.highlightTexture then self.texture = self.highlightTexture end
  else
      if self.defaultTexture then self.texture = self.defaultTexture end
  end

  if self:isAwake() then
    local spec = self:specification()
    self:updateComponents({
      material=spec.material,
      transform=spec.transform
    })
  end
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
    self.texture = asset
    self.color = {1, 1, 1, 1}
    if self:isAwake() then
      local mat = self:specification().material
      self:updateComponents({
          material= mat
      })
    end
end

--- Sets the color of the button
-- Set to nil to remove the attribute.
-- @tparam table rgba A table with the desired color's r, g, b and alpha values between 0-1, e.g. `{0.8, 0.4, 0.8, 0.5}`
function Button:setColor(rgba)
    self.color = rgba
    if self:isAwake() then
      local mat = self:specification().material
      self:updateComponents({
          material= mat
      })
    end
end

return Button
