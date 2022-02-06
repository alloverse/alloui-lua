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
    self.grabOptions = {}
    self.hasCollider = false
    self.customSpecAttributes = {}
    --- A list of file extensions the view might accept as drop target. 
    self.acceptedFileExtensions = nil
    self._pointers = {}
    self._currentSound = nil
    self._tasksForAwakening = {}
    self._isSpawned = false
    self.material = {}
end

--- awake() is called when entity exists and is bound to this view.
function View:awake()
    for _, subview in ipairs(self.subviews) do
        subview:spawn()
    end
    if self.focusOnAwake then
        self:askToFocus(self.focusOnAwake)
        self.focusOnAwake = nil
    end
    for _, task in ipairs(self._tasksForAwakening) do
        task()
    end
end

--- sleep() is called when the entity for the view stops existing
function View:sleep()

end

--- does the entity for this view exist and is bound to this view?
function View:isAwake()
  return self.entity ~= nil
end

--- schedule something to do once the entity exists for this view. If it does, do the thing immediately.
-- @tparam function todo The function to run
function View:doWhenAwake(todo)
    if self:isAwake() then
        todo()
    else
        table.insert(self._tasksForAwakening, todo)
    end
end

--- If this is set to true, user can grab and move this view using the grip button.
-- @tparam Boolean grabbable Set to `true` to enable the View to be grabbed.
-- @tparam table grabOptions A table of options for the grabbable component. See [Components > grabbable](/components#grabbable)
function View:setGrabbable(grabbable, grabOptions)
    self.grabbable = grabbable
    if grabOptions then
        self.grabOptions = grabOptions
    end
    if self:isAwake() then
        self:updateComponents(self:specification())
    end
end

--- If this is set to true, the user's cursor can land on this view, and you can
-- receive pointer events. (See `onPointerChanged` and friends)
-- @tparam Boolean pointable Set to `true` to enable the View to receive pointer events.
function View:setPointable(pointable)
    self.hasCollider = pointable
    if self:isAwake() then
        self:updateComponents(self:specification())
    end
end

function View:_poseWithTransform()
    return mat4.mul(mat4.identity(), self.transform, self.bounds.pose.transform)
end

--- The mat4 describing the transform from the parent view's location to this view's location, i e
-- the location in the local coordinate system of the parent view.
function View:transformFromParent()
    return mat4.new(self.entity.components.transform.matrix)
end

--- The mat4 describing the transform in world coordinates, i e exactly where the view
-- is in the world instead of where it is relative to its parent.
function View:transformFromWorld()
    local transformFromLocal = self:isAwake() and self:transformFromParent() or self:_poseWithTransform()
    if self.superview then
        return self.superview:transformFromWorld() * transformFromLocal
    else
        return transformFromLocal
    end
end


--- Converts `point` from `other` view to this view
-- If `other` is nil then the point is assumed to be in world space
-- @tparam Point point A point in the coordinate system of `other`
-- @tparam View other The view to convert the point from
function View:convertPointFromView(point, other)
    if other then
        -- move point from other view to world
        point = other:transformFromWorld() * point
    end
    -- move point to local by taking away our transform
    point = -self:transformFromWorld() * point
    return point
end

function _arrayFromMat4(x)
  x._m = nil
  return x
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
        mySpec.grabbable = {grabbable= true}
        for k, v in pairs(self.grabOptions) do
            if v._m then v._m = nil end
            mySpec.grabbable[k] = v
        end
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

    if #tablex.keys(self.material) > 0 then
        mySpec.material = self.material
        if mySpec.material.texture and mySpec.material.texture.id then 
        mySpec.material.texture = mySpec.material.texture:id()
        end

        if not mySpec.material.texture and not mySpec.material.color then
        mySpec.material.color = ui.Color.alloWhite()
        end
    end

    if self.hasTransparency then
        if not mySpec.material then
            mySpec.material = {}
        end
        mySpec.material.hasTransparency = self.hasTransparency
    end

    if self._currentSound then
        mySpec.sound_effect = self._currentSound
    end

    table.merge(mySpec, self.customSpecAttributes)
    return mySpec
end

--- Asks the backend to update components on the server.
-- Use this to update things you've specified in :specification() but now want to change.
-- @tparam table changes A table with the desired changes, for example: {transform={...}, collider={...}}
function View:updateComponents(changes)
    if self.app == nil or self.entity == nil then return end
    changes = changes or self:specification()
    
    self.app.client:sendInteraction({
        sender_entity_id = self.entity.id,
        receiver_entity_id = "place",
        body = {
            "change_components",
            self.entity.id,
            "add_or_change", changes,
            "remove", {}
        }
    }, function(resp, respbody)
        local ok = respbody[2]
        if ok ~= "ok" then
            print("Warning: Failed to ",self,":updateComponents(",pretty.write(changes),")")
        end
    end)
end

--- Mark one or more Components as needing to have their server-side value updated ASAP
-- @tparam string|{string} components either a string with one component to update, or a list if string components
function View:markAsDirty(components)
    if not self:isAwake() then 
        -- Everyone is dirty before they wake up
        return
    end
    if type(components) == "string" then components = {components} end
    local spec = self:specification()
    if components == nil then components = tablex.keys(spec) end
    local comps = {}
    for i, component in ipairs(components) do
        comps[component] = spec[component]
    end
    self:updateComponents(comps)
end

--- Give this view an extra transform on top of the bounds. This is useful for things like
-- adding a scale effect.
-- @tparam cpml.mat4 transform The transformation matrix to set
function View:setTransform(transform)
    self.transform = transform
    if self:isAwake() then
      self:updateComponents({
          transform= {matrix= _arrayFromMat4(self:_poseWithTransform())}
      })
    end
end

--- If the entity backing this view has moved (e g grabbed by a user, or moved
-- by an animation), this won't automatically update the Pose in this view.
-- To make sure your local state reflects what is set in-world, you can call
-- this method to update your Pose to match whatever transform is set on
-- the entity in the world.
function View:resetPoseFromServer()
    self.bounds.pose = Pose(mat4.new(self.entity.components.transform.matrix))
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
    if self._wantsSpawn then return end
    self._wantsSpawn = true
    self.app.client:sendInteraction({
        sender_entity_id = self.superview.entity.id,
        receiver_entity_id = "place",
        body = {
            "spawn_entity",
            self:specification()
        }
    }, function ()
        self._isSpawned = true
    end)
end

function View:despawn()
    if not (self._wantsSpawn and self._isSpawned) then return end
    self._wantsSpawn = false
    self.app.client:sendInteraction({
        sender_entity_id = self.entity.id,
        receiver_entity_id = "place",
        body = {
            "remove_entity",
            self.entity.id
        }
    }, function(resp, body)
        local status = body[2]
        if status ~= "ok" then
            --print("Failed to despawn", self.entity.id, "//", self.viewId)
        end

        local oldEntity = self.entity
        self.entity = nil
        self._isSpawned = false
        self:sleep(oldEntity)
    end)
    for i, v in ipairs(self.subviews) do
        v:despawn()
    end
end

--- Detaches the View from its parent
--
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
        self:despawn()
    end
    self._wantsSpawn = false
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

--- Plays the given sound asset ASAP.
-- You can use playOptions to set things like `loop_count`, `volume`, `length`, `offset` etc...
-- @tparam Asset asset The asset to play
-- @tparam table playOptions A table with valid keys for the "sound_effect" component
function View:playSound(asset, playOptions)
    self._currentSound = playOptions or {}
    if self._currentSound.finish_if_orphaned == nil then
        self._currentSound.finish_if_orphaned = true
    end
    self._currentSound.asset = asset:id()
    self._currentSound.starts_at = self.app:_timeForPlayingSoundNow()
    if self:isAwake() then
        local spec = self:specification()
        self:updateComponents({
            sound_effect= spec.sound_effect
        })
    end
end

--- Ask the client that uses the given avatar to focus this view to take text input.
-- In other words: display the keyboard for that avatar.
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

--- Dismiss the keyboard for the user that has currently keyboard-focused this view.
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
function View:onGrabStarted(hand)
end

--- Callback called when a user lets go of and no longer wants to move it.
-- @tparam Entity hand The hand entity that released the grab.
function View:onGrabEnded(hand)
end

--- Callback for when a hand is interacting with a view. 
-- NOTE: You must set view:setPointable(true), or the user's cursor will just
-- fall right through this view!
--
-- This is a catch-all callback; there is also
-- onPointerEntered, onPointerMoved, onPointerExited, onTouchDown and onTouchUp
-- if you want to react only to specific events.
-- @tparam table pointer A table with keys (see below).
--
-- The `pointer` table's keys are as follows:
--  * `hand`: The hand entity that is doing the pointing
--  * `state`: "hovering", "outside" or "touching"
--  * `touching`: bool, whether the hand is currently doing a poke on this view
--  * `pointedFrom`: a vec3 in world coordinate space with the coordinates of the finger tip of the hand pointing at this view.
--  * `pointedTo`: the point on this view that is being pointed at (again, in world coordinates).
--
function View:onPointerChanged(pointer)
end

--- Callback for when a hand's pointer ray entered this view.
--  The `state` in `pointer` is now "hovering"
-- @tparam table pointer see onPointerChanged.
function View:onPointerEntered(pointer)
end

--- Callback for when a hand's pointer moved within this view.
--  The `pointedFrom` and `pointedTo` in `pointer` now likely have new values.
-- @tparam table pointer see onPointerChanged.
function View:onPointerMoved(pointer)
end

--- Callback for when the hand's pointer is no longer pointing within this view.
--  The `state` in `pointer` is now "outside"
-- @tparam table pointer see onPointerChanged.
function View:onPointerExited(pointer)
end

--- Callback for when the hand's pointer is poking/touching this view
--  The `state` in `pointer` is now "touching"
-- @tparam table pointer see onPointerChanged.
function View:onTouchDown(pointer)
end

--- Callback for when the hand's pointer stopped poking/touching this view.
--  This is a great time to invoke an action based on the touch.
--  For example, if you're implementing a button, this is where you'd 
--  trigger whatever you're trying to trigger.
--
--  NOTE: If pointer.state is now "outside", the user released
--  the trigger button outside of this view, and you should NOT
--  perform an action, but cancel it instead.
-- @tparam table pointer see onPointerChanged.
function View:onTouchUp(pointer)
end

function View:onCapturedButtonPressed(hand, handName, buttonName)
end
function View:onCapturedButtonReleased(hand, handName, buttonName)
end
function View:onCapturedAxis(hand, handName, axisName, data)
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
            self:onGrabStarted(sender)
        else
            self:onGrabEnded(sender)
        end
    elseif body[1] == "point" then
        self:_routePointing(body, sender)
    elseif body[1] == "point-exit" then
        self:_routeEndPointing(body, sender)
    elseif body[1] == "poke" then
        self:_routePoking(body, sender)
    elseif body[1] == "captured_button_pressed" then
        self:onCapturedButtonPressed(sender, body[2], body[3])
    elseif body[1] == "captured_button_released" then
        self:onCapturedButtonReleased(sender, body[2], body[3])
    elseif body[1] == "captured_axis" then
        self:onCapturedAxis(sender, body[2], body[3], body[4])
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

--- Add an animation of a property of a component to this view
-- For example, you might want to add a one-second animation of `transform.matrix.rotation.x`
-- from 0 to 6.28, repeating. 
-- @tparam [PropertyAnimation](PropertyAnimation) anim The animation to add to this view.
function View:addPropertyAnimation(anim)
    if anim.start_at == 0 then
        anim.start_at = self.app:serverTime()
    end
    assert(anim.id == nil)
    if type(anim.from) == "table" and anim.from._m then anim.from._m = nil end
    if type(anim.to) == "table" and anim.to._m then anim.to._m = nil end
    self.app.client:sendInteraction({
        sender_entity_id = self.entity.id,
        receiver_entity_id = "place",
        body = {
            "add_property_animation",
            tablex.copy(anim)
        }
    }, function(response, body)
        if body[2] ~= "ok" then
            local errorMessage = body[3]
            print("Failed to add animation for "..anim.path.." on "..self.entity.id..": "..errorMessage)
            return
        end

        local animationId = body[3]
        anim.id = animationId
        anim.view = self
    end)
    return anim
end


--- Set the Surface's texture using an Asset.
-- The `asset` parameter can be either an [Asset](asset) instance or a raw string hash
--
--~~~ lua
-- Surface:setTexture(asset)
--~~~
--
-- @tparam [Asset](asset) asset An instance of an Asset
function View:setTexture(asset)
    self.material.texture = asset
    self:markAsDirty("material")
end


--- Set the color of a Surface using a set of rgba values between 0 and 1.
-- E.g. to set the surface to be red and 50% transparent, set this value to `{1, 0, 0, 0.5}`
--
--~~~ lua
-- Surface:setColor(rgba)
--~~~
--
-- @tparam table rgba A table defining a color value with alpha between 0-1.
function View:setColor(rgba)
    self.material.color = rgba
    self:markAsDirty("material")
end

return View
