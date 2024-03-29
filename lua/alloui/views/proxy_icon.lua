--- Proxy icon: A grabbable 3d object that creates a copy that can be placed in the world.
--
-- Useful as a way to instantiate objects in the world from a palette. Subclass it and override
-- onIconDropped().
-- @classmod ProxyIconView

local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local vec3 = require("modules.vec3")
local mat4 = require("modules.mat4")
local Bounds = require(modules .."bounds")
local Size = require(modules .."size")
local Color = require(modules .."color")
local View = require(modules .."views.view")
local ModelView = require(modules .."views.modelview")

class.ProxyIconView(View)
---
--~~~ lua
-- icon = ProxyIconView(bounds)
--~~~
--@tparam [Bounds](bounds) bounds The icon's bounds.
--@tparam String name The asset's name
--@tparam String author The asset's author
--@tparam [FileAsset](FileAsset) icon asset to be used as the icon for this proxy view 
function ProxyIconView:_init(bounds, name, author, icon)
    self:super(bounds)
    self.name = name
    self.iconAsset = icon
    self:makeIcon()

    self.brick = self:addSubview(ui.Cube(
        ui.Bounds{size=bounds.size:copy()}
        -- :insetEdges(0.05, 0.05, 0.05, 0.05, 0.00, 0.05)
        :move(0, 0, -0.05)
    ))
    self.brick.color = Color.alloDarkBlue()
    self.brick.color[4] = 0.2
    self.nameLabel = self:addSubview(
        ui.Label{
            bounds= ui.Bounds(0, 0, 0,   bounds.size.width, 0.04, 0.01)
                :move(0, -bounds.size.height/2 + 0.08, 0),
            text= name,
            color = {1, 1, 1, 1},
            fitToWidth = true
        }
    )
    if author then
      self.authorLabel = self:addSubview(
          ui.Label{
              bounds= ui.Bounds(0, 0, 0,   bounds.size.width, 0.03, 0.01)
                  :move(0, -bounds.size.height/2 + 0.03, 0),
              text= author,
              color = {1, 1, 1, 1},
              fitToWidth = true
          }
      )
    end
end

function ProxyIconView:makeIcon()
    self.icon = ui.View(
        ui.Bounds{size=self.bounds.size:copy()}:move(0, 0, 0.05)
    )
    self.iconModel = self.icon:addSubview(ui.ModelView(
        ui.Bounds{size=self.bounds.size:copy()},
        self.iconAsset
    ))

    self.iconModel.color = Color.alloDarkGray()
    self.icon:setPointable(true)
    self.icon:setGrabbable(true, {target_hand_transform= mat4.identity()})
    self.icon.onGrabStarted = function()
        self:makeIcon()
    end
    self.icon.onGrabEnded = function(oldIcon)
        local m_at = oldIcon.entity.components.transform:transformFromWorld()
        if self:onIconDropped(m_at, oldIcon) then
            oldIcon:removeFromSuperview()
        end
    end
    self.icon.onPointerEntered = function()
        -- disable because it keeps getting triggered without a corresponding onPointerEnded (which is a bug in alloui or visor)
        if true then return end
        self.spinAnim = self.iconModel:addPropertyAnimation(ui.PropertyAnimation{
            path= "transform.matrix.rotation.y",
            from= 0,
            to=   3.14159*2,
            duration = 6.0,
            repeats= true,
      })
    end
    self.icon.onPointerExited = function()
        if self.spinAnim then
            self.spinAnim:removeFromView()
            self.iconModel:setBounds()
            self.spinAnim = nil
        end
    end
    self:addSubview(self.icon)
end

--- Override this to handle the icon being dropped. You can also set it
-- as a property on the instantiated icon view.
function ProxyIconView:onIconDropped(at_transform)
    
end

return ProxyIconView
