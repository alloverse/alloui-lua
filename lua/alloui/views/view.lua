local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local vec3 = require("modules.vec3")
local mat4 = require("modules.mat4")
require(modules .."random_string")

-- The view class acts as base for anything visual in an alloapp. It
-- manages a tree of sub-views; its bounds (transform and size);
-- and a connection to a low-level entity.
class.View()
function View:_init(bounds)
    self.viewId = string.random(16)
    self.bounds = bounds
    -- a transform applied on top of the bounds. Use for temporary adjustments, e g scale.
    self.transform = mat4.identity()
    self.subviews = {}
    self.entity = nil
    self.app = nil
end

-- awake() is called when entity exists and is bound to this view.
function View:awake()
end

function View:isAwake()
  return self.entity ~= nil
end

function View:_poseWithTransform()
    local out = mat4.identity()
    mat4.mul(out, self.transform, self.bounds.pose.transform)
    out._m = nil
    return out
end

-- The specification is used to describe the entity three required to represent
-- this view inside the Alloverse. In a subclass, call this implementation and then
-- add/modify your own components.
function View:specification()
    local mySpec = {
        ui = {
            view_id = self.viewId
        },
        transform = {
            matrix = self:_poseWithTransform()
        },
        children = tablex.map(function(v) return v:specification() end, self.subviews)
    }
    return mySpec
end

-- Ask backend to update components on the server. Use to update things you've specified
-- in :specification() but now want to change.
function View:updateComponents(changes)
    self.app.client:sendInteraction({
        sender_entity_id = self.entity.id,
        receiver_entity_id = "place",
        body = {
            "change_components",
            self.entity.id,
            "add_or_change", changes,
            "remove", {}
        }
      })
end

function View:setTransform(transform)
    self.transform = transform
    self:updateComponents({
        transform= {matrix= self:_poseWithTransform()}
    })
end

function View:addSubview(subview)
    table.insert(self.subviews, subview)
    subview.app = self.app
end

function View:findView(vid)
    if self.viewId == vid then
        return self
    end
    for i, v in ipairs(self.subviews) do
        local found = v:findView(vid)
        if found then
            return found
        end
    end
    return nil
end

function View:setApp(app)
    self.app = app
    for i, v in ipairs(self.subviews) do
        v:setApp(app)
    end
end

-- an interaction message was sent to this specific view.
-- See https://github.com/alloverse/docs/blob/master/specifications/interactions.md
function View:onInteraction(inter, body, sender)
end

return View