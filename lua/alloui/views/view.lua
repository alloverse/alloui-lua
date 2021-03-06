--- A view
--@classmod View

local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local vec3 = require("modules.vec3")
local mat4 = require("modules.mat4")
require(modules .."random_string")
local Bounds = require(modules .."bounds")

--- The view class acts as base for anything visual in an alloapp. It
-- manages a tree of sub-views; its bounds (transform and size);
-- and a connection to a low-level entity.
class.View()
-- Export assets
View.assets = {}
function View:_init(bounds)
    self.viewId = string.random(16)
    self.bounds = bounds and bounds or Bounds(0,0,0, 0,0,0)
    -- a transform applied on top of the bounds. Use for temporary adjustments, e g scale.
    self.transform = mat4.identity()
    self.subviews = {}
    self.entity = nil
    self.app = nil
    self.grabbable = false
    self.customSpecAttributes = {}
end

-- awake() is called when entity exists and is bound to this view.
function View:awake()
    for _, subview in ipairs(self.subviews) do
        subview:spawn()
    end
    if self.focusOnAwake then
        self:askToFocus(self.focusOnAwake)
        self.focusOnAwake = nil
    end
end

function View:isAwake()
  return self.entity ~= nil
end

function View:_poseWithTransform()
    return mat4.mul(mat4.identity(), self.transform, self.bounds.pose.transform)
end

function View:transformFromParent()
    return mat4.new(self.entity.components.transform.matrix)
end

function View:transformFromWorld()
  if self:isAwake() then
    local transformFromLocal = self:transformFromParent()
    if self.superview ~= nil then
        return mat4.mul(mat4.identity(), self.superview:transformFromWorld(), transformFromLocal)
    else
        return transformFromLocal
    end
  else
    local transformFromLocal = self:_poseWithTransform()
    if self.superview ~= nil then
        return mat4.mul(mat4.identity(), self.superview:transformFromWorld(), transformFromLocal)
    else
        return transformFromLocal
    end
  end
end

function _arrayFromMat4(x)
  x._m = nil
  return x
end

local function merge(t, u)
    if t == nil or u == nil then return end
    for key, _ in pairs(u) do
        local left = t[key]
        local right = u[key]
        if type(left) == "table" and type(right) == "table" then
            merge(left, right)
        else
            if type(u[key]) == "table" then 
                t[key] = tablex.deepcopy(u[key])
            else
                t[key] = u[key]
            end
        end
    end
end

--- The specification is used to describe the entity three required to represent
-- this view inside the Alloverse. In a subclass, call this implementation and then
-- add/modify your own components.
function View:specification()
    local mySpec = {
        ui = {
            view_id = self.viewId
        },
        transform = {
            matrix = _arrayFromMat4(self:_poseWithTransform())
        },
    }
    if self.superview and self.superview:isAwake() then
        mySpec.relationships = {
            parent = self.superview.entity.id
        }
    end
    if self.grabbable then
        local s = self.bounds.size
        mySpec.grabbable = {grabbable= true}
        mySpec.collider = {
            type= "box",
            width= s.width, height= s.height, depth= s.depth
        }
    end
    merge(mySpec, self.customSpecAttributes)
    return mySpec
end

--- Ask backend to update components on the server. Use to update things you've specified
-- in :specification() but now want to change.
function View:updateComponents(changes)
    if self.app == nil or self.entity == nil then return end
    
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
    if self:isAwake() then
      self:updateComponents({
          transform= {matrix= _arrayFromMat4(self:_poseWithTransform())}
      })
    end
end

function View:setBounds(bounds)
  if bounds == nil then bounds = self.bounds end
  self.bounds = bounds
  if self:isAwake() then
    local c = self:specification()
    self:updateComponents({
        transform= c.transform,
        collider= c.collider
    })
  end
end

function View:addSubview(subview)
    assert(subview.superview == nil)

    table.insert(self.subviews, subview)
    subview:setApp(self.app)
    subview.superview = self
    if self:isAwake() then
        subview:spawn()
    end -- else, wait for awake()
    return subview
end

function View:spawn()
    assert(self.superview and self.superview:isAwake())
    self.app.client:sendInteraction({
        sender_entity_id = self.superview.entity.id,
        receiver_entity_id = "place",
        body = {
            "spawn_entity",
            self:specification()
        }
    })
end

function View:removeFromSuperview()
    if self.superview then
        local idx = tablex.find(self.superview.subviews, self)
        assert(idx ~= -1)
        table.remove(self.superview.subviews, idx)
    else
        local idx = tablex.find(self.app.rootViews, self)
        assert(idx ~= -1)
        table.remove(self.app.rootViews, idx)
    end
    if self:isAwake() then
        self.app.client:sendInteraction({
            sender_entity_id = self.entity.id,
            receiver_entity_id = "place",
            body = {
                "remove_entity",
                self.entity.id
            }
        }, function()
            self.entity = nil
        end)
    end
    self.superview = nil
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
    if self.app then self:registerAssets() end

    for i, v in ipairs(self.subviews) do
        v:setApp(app)
    end
end

function View:registerAssets()
    local mt = getmetatable(self)
    while mt do
        self.app.assetManager:add(mt.assets or {})
        mt = mt._base
    end
end

function View:askToFocus(avatar)
    if not self:isAwake() then 
        self.focusOnAwake = avatar
        return
    end
    self.app.client:sendInteraction({
        sender = self.entity,
        receiver = avatar,
        body = {
            "changeFocusTo",
            self.entity.id
        }
    })
end

function View:onFocus(by)
    if self.focusedBy then
        self:defocus()
    end
    self.focusedBy = by
    return true
end

function View:defocus()
    self.app.client:sendInteraction({
        sender = self.entity,
        receiver = self.focusedBy,
        body = {
            "defocus"
        }
    })
end

--- an interaction message was sent to this specific view.
-- See https://github.com/alloverse/docs/blob/master/specifications/interactions.md
function View:onInteraction(inter, body, sender)
    if body[1] == "focus" then
        local ok = self:onFocus(sender)
        inter:respond({"focus", ok and "ok" or "denied"})
    elseif body[1] == "defocus" then
        if self.focusedBy and sender.id == self.focusedBy.id then
            self:onFocus(nil)
        end
    end
end

return View
