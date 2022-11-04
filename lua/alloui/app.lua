--- Represents the AlloApp.
-- Mediates communication with backend, and maintains the runloop. Create one of these, configure it,
-- connect it and run it, and you have an alloapp.
-- @classmod App
local modules = (...):gsub(".[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local util = require(modules .."util")
local Asset = require(modules .. "asset.init")

local function log(t, message)
    allo_log(t, "app", nil, message)
end

local ScheduledAction = class.ScheduledAction()

--- Schedule work to be done later
-- 
-- @tparam Client client The AlloNet client
-- @tparam number delay The time (in seconds) until the callback is called.
-- @tparam boolean repeats Whether The callback should repeat (with the same delay) or only occur once.
-- @tparam function callback The function to be called (with no arguments).
function ScheduledAction:_init(client, delay, repeats, callback)
    self.delay = delay
    self.repeats = repeats
    self.callback = callback
    self.when = client:getClientTime() + delay
end

class.App()

App.ScheduledAction = ScheduledAction
App.launchArguments = {}

---
--
--~~~ lua
-- local app = App(client)
--~~~
--
-- @tparam [Client](Client) client The AlloNet client wrapper
function App:_init(client)
    self.client = client
    self.mainView = View()
    self.dirtyViews = {}
    self.rootViews = {}
    self.running = true
    self.connected = false
    self.videoSurfaces = {}
    client.delegates.onInteraction = function(inter, body, receiver, sender) 
        self:onInteraction(inter, body, receiver, sender) 
    end
    client.delegates.onComponentAdded = function(cname, comp)
        self:onComponentAdded(cname, comp)
    end
    client.delegates.onComponentRemoved = function(cname, comp)
        self:onComponentRemoved(cname, comp)
    end
    client.delegates.onDisconnected = function(code, message)
        self.connected = false
        print("DISCONNECTED", code, message)
        self.running = false
    end
    client.delegates.onConnected = function()
        self.connected = true

        log("INFO", string.format("App started successfully! Open the Alloverse Visor and connect to %s to see it in action!", client.url))

        if self.onConnected then 
            self:onConnected()
        end
    end
    self.scheduledActions = {}
    self.assetManager = AssetManager(client)
end

function App:connect()
    if App.initialLocation then
        self.mainView.bounds.pose.transform = App.initialLocation
    end
    
    local mainSpec = self.mainView:specification()
    if App.launchArguments.avatarToken then
        -- used to associate a launch request with a specific avatar
        mainSpec.avatar = {token= App.launchArguments.avatarToken}
    end
    self:addRootView(self.mainView)
    local ret = self.client:connect(mainSpec)
    if not ret then
        error("Failed to connect")
    end
    self:onConnectionEstablished()
    return ret
end
function App:onConnectionEstablished()
    for _, v in ipairs(self.rootViews) do
        v._isSpawned = true
        v:setApp(self)
        if v ~= self.mainView then
            v._wantsSpawn = true
            self.client:spawnEntity(v:specification())
        end
    end
    return ret
end

function App:setMainView(newMainView)
    self.mainView = newMainView
    self.mainView:setApp(self)
end

function App:addRootView(view, cb)
    table.insert(self.rootViews, view)
    view._wantsSpawn = true
    if self.connected then
        view:setApp(self)
        self.client:spawnEntity(view:specification(), function(entityOrFalse)
            view._isSpawned = true
            if cb then
                cb(entityOrFalse and view or false, entityOrFalse)
            end
        end)
    end
    return view
end

--- Open a ui.View as a popup near a hand. Call from e g a button handler to
-- display it right where the user could easily interact with it. You can use this
-- to open a "new item" or a "settings" UI near a user. Since apps are multi-user,
-- sometimes it's nice to give a user some personal UI that they can do input in,
-- so that they don't have to fight over control of input with another user.
-- @tparam ui.View popup The view to show to the user. It will be instantiated in
--                       the world at the appropriate location.
-- @tparam Entity hand   The hand entity that the popup should be shown near.
--                       In a button handler, this is the first argument to the callback.
-- @tparam number distance The distance in meters from the hand to show. Default 0.6
-- @tparam Callback(view, entity) cb The callback to call when the popup is present in-world 
function App:openPopupNearHand(popup, hand, distance, cb)
    if distance == nil then distance = 0.8 end

    local h = hand.components.transform:transformFromWorld()
    local d = mat4.identity():translate(mat4.identity(), vec3(0, 0, -distance))
    popup.bounds.pose = ui.Pose(h * d)
    
    self:addRootView(popup, cb)
    return popup
end

--- Add a widget to the user's left wrist, and arrange it to fit with the other
-- widgets already present. Use this to provide some portable UI to the user,
-- such as a remote control.
-- @tparam Entity avatarOrHand The avatar of the user to add the widget to. Can also be any
--                             child entity to the avatar, such as a hand, and the avatar will
--                             be looked up for you.
-- @tparam ui.View widget The widget to add. Must be at most 3cm wide. You can make it a button
--                        or something that opens more UI nearby if you need more space.
-- @tparam Callback(bool) callback Callback for when adding widget finishes. Its argument is true
--                                 if successful. 
function App:addWristWidget(avatarOrHand, widget, callback)
    self:addRootView(widget, function(widgetView, widgetEnt)
        if widgetView == nil then
            if callback then callback(false) end
            return
        end
        local avatar = avatarOrHand:getAncestor()
        self.client:sendInteraction({
            receiver_entity_id = avatar.id,
            body = {
                "add_wrist_widget",
                widgetEnt.id
            }
        }, function(resp, body)
            if body[2] ~= "ok" then
                widget:removeFromSuperview()
                if callback then callback(false) end
                return
            else
                -- because avatar will move widget
                -- late addition to protocol: response has the position that the avatar moved the
                -- widget to (since interaction response might be before we get statediff with new position)
                if body[3] then
                    widget.entity.components.transform.matrix = body[3]
                end
                widget:resetPoseFromServer()
                if callback then callback(true) end
            end
        end)
    end)
end

function compareActions(a, b)
    return a.when < b.when
end

--- Schedule work to be done later
-- 
-- @tparam number delay The time (in seconds) until the callback is called.
-- @tparam boolean repeats Whether The callback should repeat (with the same delay) or only occur once.
-- @tparam function callback The function to be called (with no arguments).
function App:scheduleAction(delay, repeats, callback)
    local action = ScheduledAction(self.client, delay, repeats, callback)
    table.bininsert(self.scheduledActions, action, compareActions)
    return {
        cancel = function ()
            action.repeats = false
            for k,v in ipairs(self.scheduledActions) do
                if self.scheduledActions[k] == action then 
                    table.remove(self.scheduledActions, k)
                    return
                end
            end
        end
    }
end

function App:run(hz)
    xpcall(function()
        self:_run(hz)
    end, function(err)
        print("Error while running "..self.client.name..":\n", err,"\n", debug.traceback())
    end)
    print("Exiting "..self.client.name)
    if self.onBeforeQuit then self.onBeforeQuit() end
    
    self.client:disconnect(0)
end

function App:_run(hz)
    hz = hz and hz or 40.0
    while self.running do
        self:runOnce(1.0/hz)
    end
end

function App:quit()
    self.running = false
end

function App:runOnce(timeout)
  self.latestTimeout = timeout
  local nextAction = self.scheduledActions[1]
  local now = self:clientTime()
  if nextAction and nextAction.when < now then
      table.remove(self.scheduledActions, 1)
      nextAction.when = nextAction.when + nextAction.delay
      nextAction.callback()
      if nextAction.repeats then
          table.bininsert(self.scheduledActions, nextAction, compareActions)
      end
  end
  self:_cleanViews()
  self.client:poll(timeout)
end

function App:runFor(secs)
    local now = self:clientTime()
    while self:clientTime() < now + secs do
        app:runOnce(0.1)
    end
end

function App:findView(vid)
    for _, v in ipairs(self.rootViews) do
        local found = v:findView(vid)
        if found then
            return found
        end
    end
    return nil
end

function App:onInteraction(inter, body, receiver, sender) 
    if receiver == nil or receiver.components.ui == nil then return end
    if receiver.id == self.client.avatar_id then
        self:onAppInteraction(inter, body, receiver, sender)
        return
    end
    local vid = receiver.components.ui.view_id
    local view = self:findView(vid)
    if view then
        view:onInteraction(inter, body, sender)
    else
        print("warning: got interaction", body[1], "for nonexistent vid ", vid, "eid", receiver.id)
    end
end

function App:onAppInteraction(inter, body, receiver, sender)
    if body[1] == "quit" then
        print("Was asked to quit by", sender.id, ", obliging")
        inter:respond({"quit", "ok"})
        self:quit()
    end
end

function App:onComponentAdded(cname, comp)
    if cname == "ui" then
        local vid = comp.view_id
        local view = self:findView(vid)
        if view then 
            if view._wantsSpawn then 
                view.entity = comp:getEntity()
                view:awake()
            else
                print("Entity", comp:getEntity().id, "was added for view", view, "that was already removed from superview: deleting entity", debug.traceback())
                local ent = comp:getEntity()
                self.client:sendInteraction({
                    sender_entity_id = ent.id,
                    receiver_entity_id = "place",
                    body = {
                        "remove_entity",
                        ent.id
                    }
                })
            end
        end
    elseif cname == "visor" then 
        local name = comp.display_name
        local eid = comp.getEntity().id
        self:onVisorConnected(comp.getEntity(), name)
    end
end

function App:onComponentRemoved(cname, comp)
    if cname == "ui" then
        local vid = comp.view_id
        local view = self:findView(vid)
        if view then
            print("Lost view", vid, "because its entity", comp.getEntity().id, "was removed from server state")
            view.entity = nil
            view:removeFromSuperview()
            view:sleep()
        end
    elseif cname == "visor" then
        local eid = comp.getEntity().id
        self:onVisorDisconnected(eid)
    end
end

function App:_scheduleForCleaning(view)
    self.dirtyViews[view.viewId] = view
end

function App:_cleanViews()
    if next(self.dirtyViews) == nil then return end

    for vid, view in pairs(self.dirtyViews) do
        if view.entity then
            view:clean()
            self.dirtyViews[vid] = nil
        end
    end
end

function App:onVisorConnected(entity, name)
    -- ask all videos to send the recent frame so the new player gets it
    for _, video in ipairs(self.videoSurfaces) do
        video:sendLastFrame()
    end
end

function App:onVisorDisconnected(eid)

end

function App:_getInternalAsset(name)
    if not self._internalAssets then self._internalAssets = {} end
    if not self._internalAssets[name] then
        if lovr then
            self._internalAssets[name] = self.assetManager:add(Asset.LovrFile("lib/alloui/assets/"..name))
        else
            self._internalAssets[name] = self.assetManager:add(Asset.File("./allo/deps/alloui/assets/"..name))
        end
    end
    return self._internalAssets[name]
end

--- Current client time. This is monotonically increasing.
function App:clientTime()
    return self.client:getClientTime()
end
--- Current server time. Might jump around a little to compensate for lag.
function App:serverTime()
    return self.client:getServerTime()
end

function App:_timeForPlayingSoundNow()
    return self:serverTime() + (self.latestTimeout or 0.05)
end

function App:addVideoSurface(surface)
    table.insert(self.videoSurfaces, surface)
end

function App:removeVideoSurface(surface)
    for i,v in ipairs(self.videoSurfaces) do
        if v == surface then table.remove(self.videoSurfaces, i) end
    end
end

return App
