--- The View class acts as base for anything visual in an alloapp.
-- It manages a tree of sub-views; its bounds (transform and size) and a connection to a low-level entity.
-- @classmod View

local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local vec3 = require("modules.vec3")
local mat4 = require("modules.mat4")
require(modules .."random_string")
local Bounds = require(modules .."bounds")


class.View()
-- Export assets
View.assets = {}

---
--~~~ lua
-- view = View(bounds)
--~~~
--@tparam [Bounds](bounds) bounds The View's Bounds component
function View:_init(bounds)
    self.viewId = string.random(16)
    self.bounds = bounds and bounds or Bounds(0,0,0, 0,0,0)
    -- a transform applied on top of the bounds. Use for temporary adjustments, e g scale.
    self.transform = mat4.identity()
    self.subviews = {}
    self.entity = nil
    self.app = nil
    self.grabbable = false
    self.hasCollider = false
    self.customSpecAttributes = {}
    --- A list of file extensions the view might accept as drop target. 
    self.acceptedFileExtensions = nil
    self._pointers = {}
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

--- If this is set to true, user can grab and move this view using the grip button.
function View:setGrabbable(grabbable)
    self.grabbable = grabbable
    if self:isAwake() then
        self:updateComponents(self:specification())
    end
end

--- If this is set to true, the user's cursor can land on this view, and you can
-- receive pointer events. (See `onPointerChanged` and friends)
function View:setPointable(pointable)
    self.hasCollider = pointable
    if self:isAwake() then
        self:updateComponents(self:specification())
    end
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

--- The specification is used to describe the entity tree.  
-- It is required to represent this view inside the Alloverse.
-- In a subclass, call this implementation and then add/modify your own components.
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
    end

    if self.grabbable or self.hasCollider then
        local s = self.bounds.size
        mySpec.collider = {
            type= "box",
            width= s.width, height= s.height, depth= s.depth
        }
    end

    if self.acceptedFileExtensions then
        mySpec.acceptsfile = {
            extensions = self.acceptedFileExtensions
        }
    end

    if self.hasTransparency then
        if not mySpec.material then
            mySpec.material = {}
        end
        mySpec.material.hasTransparency = self.hasTransparency
    end

    merge(mySpec, self.customSpecAttributes)
    return mySpec
end

--- Asks the backend to update components on the server.
-- Use this to update things you've specified in :specification() but now want to change.
-- @tparam table changes A table with the desired changes, for example: {transform={...}, collider={...}}
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

--- Sets the View's bounds (pose and size) in the world.
-- Note that simply changing a View's Bounds won't affect its size or position in the world until this method is run.
-- @tparam [Bounds](bounds) bounds the Bounds with which to define the Size and Pose of the parent View in the world.
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

--- Adds a View as a child component to the given View.
--
-- @tparam [View](view) subview The View to be added 
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

--- Finds and returns a subview of the given view ID.
--
-- @tparam string vid The viewId of the View to be searched for.
-- @treturn [View](view) The subview corresponding to the view ID. If no view was found, `nil` is returned.
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

--- Callback called when a user grabs this view in order to move it.
-- The server will then update self.entity.components.transform to match
-- where the user wants to move it continuously. There is no callback for
-- when the entity is moved.
-- @tparam Entity hand The hand entity that started the grab
function View:grabStarted(hand)
end

--- Callback called when a user lets go of and no longer wants to move it.
-- @tparam Entity hand The hand entity that released the grab.
function View:grabEnded(hand)
end

--- Callback for when a hand is interacting with a view. This is a catch-all
-- callback; there is also onPointerEntered, onPointerMoved, onPointerExited,
-- onTouchDown and onTouchUp if you want to react only to specific events.
-- @tparam table pointer A table with keys:
--  * `hand`: The hand entity that is doing the pointing
--  * `state`: "hovering", "outside" or "touching"
--  * `touching`: bool, whether the hand is currently doing a poke on this view
--  *`pointedFrom`: a vec3 in world coordinate space with the coordinates 
--                  of the finger tip of the hand pointing at this view.
--  * `pointedTo`: the point on this view that is being pointed at
--                 (again, in world coordinates).
function View:onPointerChanged(pointer)
end

--- Callback for when a hand's pointer ray entered this view.
--  The `state` in pointer is now "hovering"
-- @tparam table pointer see onPointerChanged.
function View:onPointerEntered(pointer)
end

--- Callback for when a hand's pointer moved within this view.
--  The pointedFrom and pointedTo in pointer now likely have new values.
-- @tparam table pointer see onPointerChanged.
function View:onPointerMoved(pointer)
end

--- Callback for when the hand's pointer is no longer pointing within this view.
--  The `state` in pointer is now "outside"
-- @tparam table pointer see onPointerChanged.
function View:onPointerExited(pointer)
end

--- Callback for when the hand's pointer is poking/touching this view
--  The `state` in pointer is now "touching"
-- @tparam table pointer see onPointerChanged.
function View:onTouchDown(pointer)
end

--- Callback for when the hand's pointer stopped poking/touching this view.
--  This is a great time to invoke an action based on the touch.
--  For example, if you're implementing a button, this is where you'd 
--  trigger whatever you're trying to trigger.
--  NOTE: If pointer.state is now "outside", the user released
--  the trigger button outside of this view, and you should NOT
--  perform an action, but cancel it instead.
-- @tparam table pointer see onPointerChanged.
function View:onTouchUp(pointer)
end

--- an interaction message was sent to this specific view.
-- See [Interactions](/protocol-reference/interactions)
function View:onInteraction(inter, body, sender)
    if body[1] == "focus" then
        local ok = self:onFocus(sender)
        inter:respond({"focus", ok and "ok" or "denied"})
    elseif body[1] == "defocus" then
        if self.focusedBy and sender.id == self.focusedBy.id then
            self:onFocus(nil)
        end
    elseif body[1] == "accept-file" and body[2] and body[3] then 
        self:onFileDropped(body[2], body[3])
    elseif body[1] == "grabbing" then
        if body[2] then
            self:grabStarted(sender)
        else
            self:grabEnded(sender)
        end
    elseif body[1] == "point" then
        self:_routePointing(body, sender)
    elseif body[1] == "point-exit" then
        self:_routeEndPointing(body, sender)
    elseif body[1] == "poke" then
        self:_routePoking(body, sender)
    end
end

function View:_routePointing(body, sender)
    local pointer = self._pointers[sender.id]
    if pointer == nil then
        pointer = {
            hand= sender,
            state= nil,
            touching= false,
        }
        self._pointers[sender.id] = pointer
    end
    pointer.pointedFrom = vec3(unpack(body[2]))
    pointer.pointedTo = vec3(unpack(body[3]))

    if pointer.state == nil then
        pointer.state = "hovering"
        self:onPointerEntered(pointer)
    else
        self:onPointerMoved(pointer)
    end
    self:onPointerChanged(pointer)
end
function View:_routeEndPointing(body, sender)
    local pointer = self._pointers[sender.id]
    if not pointer then return end
    pointer.state = "outside"
    pointer.pointedFrom = nil
    pointer.pointedTo = nil
    self:onPointerExited(pointer)
    self:onPointerChanged(pointer)
    self._pointers[sender.id] = nil
end
function View:_routePoking(body, sender)
    local pointer = self._pointers[sender.id]
    if not pointer then return end
    if body[2] then
        pointer.touching = true
        pointer.state = "touching"
        self:onTouchDown(pointer)
    else
        pointer.touching = false
        pointer.state = pointer.pointedFrom and "hovering" or "outside"
        self:onTouchUp(pointer)
    end
    self:onPointerChanged(pointer)
end

--- Callback called when a file is dropped on the view
-- @tparam string filename The name of the dropped file
-- @tparam string asset_id The id of the asset dropped on you
function View:onFileDropped(filename, asset_id)
end

return View
