--- A window resize widget.
-- Grab and move to resize your view from its center point.
-- @classmod ResizeHandle


local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local ModelView = require(modules.."views.modelview")
local Base64Asset = require(modules.."asset.init").Base64


class.ResizeHandle(View)

--- 
--
--~~~ lua
-- resizeHandle = ResizeHandle(bounds, translationConstraint, rotationConstraint)
--~~~
--
-- @tparam Bounds bounds The ResizeHandle's bounds.
-- @tparam table translationConstraint Only allow the indicated fraction of movement in the corresponding axis in the actuated entity’s local coordinate space. E g, to only allow movement along the floor (no lifting), set the y fraction to 0: `{1, 0, 1}`.
-- @tparam table rotationConstraint Similarly, constrain rotation to the given fraction in the given euler axis in the actuated entity’s local coordinate space. E g, to only allow rotation along Y (so that it always stays up-right), use: `{0, 1, 0}`.
function ResizeHandle:_init(bounds, translationConstraint, rotationConstraint)
  self:super(bounds)

  self.ridges = self:addSubview(ModelView(ui.Bounds.unit(), app:_getInternalAsset("models/resizehandle.glb")))

  self.isHover = false
  self.onActivated = nil
  self.active = false -- is grabbed and doing resizing
  self.translationConstraint = translationConstraint
  self.rotationConstraint = rotationConstraint
  self.hasTransparency = true
  self:layout()
end

function ResizeHandle:specification()
  local s = self.bounds.size
  local w2 = s.width / 2.0
  local h2 = s.depth / 2.0
  local mySpec = table.merge(View.specification(self), {
      collider= {
          type= "box",
          width= s.width, height= s.height, depth= s.depth
      },
      grabbable= {
        translation_constraint= self.translationConstraint,
        rotation_constraint = self.rotationConstraint
      },
      cursor= {
        name= "resizeCursor"
      }
  })
  return mySpec
end

function ResizeHandle:onInteraction(inter, body, sender)
  View.onInteraction(self, inter, body, sender)
  if body[1] == "point" then
      self:setHover(true)
  elseif body[1] == "point-exit" then
      self:setHover(false)
  elseif body[1] == "poke" then
      self:setSelected(body[2])

      if self.selected == false and self.isHover == true then
          self:activate()
      end
  end
end

function ResizeHandle:setHover(isHover)
  if isHover == self.isHover then return end
  self.isHover = isHover
  self:_updateLooks()
end

function ResizeHandle:setSelected(selected)
  if selected == self.selected then return end
  self.selected = selected
  self:_updateLooks()
end

function ResizeHandle:_updateLooks()
  
end

function ResizeHandle:activate()
  if self.onActivated then
      self.onActivated()
  end
end


-- View override
function ResizeHandle:onGrabStarted(sender)
  if self.active then return end
  self.active = true
end

-- View override
function ResizeHandle:onGrabEnded(sender)
  if not self.active then return end
  self.active = false
end

function ResizeHandle:layout()
    View.layout(self)

    local angle = 0
    local cornerpos = self.bounds.pose:pos()
    if cornerpos.x > 0 and cornerpos.y > 0 then
        angle = -3.14159/2
    elseif cornerpos.x > 0 and cornerpos.y < 0 then
        angle = 3.14159
    elseif cornerpos.x < 0 and cornerpos.y < 0 then
        angle = 3.14159/2
    end
    

    local bounds = self.bounds
        :copy():moveToOrigin()
        :scale(self.bounds.size.width, self.bounds.size.height, self.bounds.size.depth)
        :rotate(angle, 0,0,1)
    self.ridges:setBounds(bounds)
end

return ResizeHandle
