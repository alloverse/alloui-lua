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

class.ScheduledAction()

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
    self.when = client.client:get_server_time() + delay
end

class.App()

App.ScheduledAction = ScheduledAction

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
    client.delegates.onDisconnected = function(code, message)
        self.connected = false
        print("DISCONNECTED", code, message)
        self.running = false
    end
    client.delegates.onConnected = function()
        self.connected = true
        if self.onConnected then 
            self:onConnected()
        end
    end
    self.scheduledActions = {}
    self.assetManager = AssetManager(client.client)
end

function App:connect()
    if App.initialLocation then
        print("Setting main view's location to", App.initialLocation)
        self.mainView.bounds.pose.transform = App.initialLocation
    end
    
    local mainSpec = self.mainView:specification()
    table.insert(self.rootViews, self.mainView)
    local ret = self.client:connect(mainSpec)
    if not ret then
        error("Failed to connect")
    end
    self:onConnectionEstablished()
    return ret
end
function App:onConnectionEstablished()
    for _, v in ipairs(self.rootViews) do
        v:setApp(self)
        if v ~= self.mainView then
            self.client:spawnEntity(v:specification())
        end
    end
    return ret
end

function App:addRootView(view, cb)
    table.insert(self.rootViews, view)
    if self.connected then
        view:setApp(self)
        self.client:spawnEntity(view:specification(), function(entityOrFalse)
            if cb then
                cb(entityOrFalse and view or false)
            end
        end)
    end
end

function App:openPopupNearHand(popup, hand, distance, cb)
    if distance == nil then distance = 0.6 end

    local handPose = ui.Pose(hand.components.transform:transformFromWorld())
    popup.bounds.pose = handPose
    popup.bounds:move(0, 0, -distance)
    self:addRootView(popup, cb)
    return popup
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
end

function App:run(hz)
    xpcall(function()
        self:_run(hz)
    end, function(err)
        print("Error while running "..self.client.name..":\n", err,"\n", debug.traceback())
    end)
    print("Exiting "..self.client.name)
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
  local now = self:now()
  if nextAction and nextAction.when < now then
      table.remove(self.scheduledActions, 1)
      nextAction.callback()
      if nextAction.repeats then
          nextAction.when = nextAction.when + nextAction.delay
          table.bininsert(self.scheduledActions, nextAction, compareActions)
      end
  end
  self.client:poll(timeout)
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
    local vid = receiver.components.ui.view_id
    local view = self:findView(vid)
    if view then
        view:onInteraction(inter, body, sender)
    else
        print("warning: got interaction", body[1], "for nonexistent vid ", vid, "eid", receiver.id)
    end
end

function App:onComponentAdded(cname, comp)
    if cname == "ui" then
        local vid = comp.view_id
        local view = self:findView(vid)
        if view then 
            view.entity = comp:getEntity()
            view:awake()
        end
    end

    if cname == "visor" then 
        local name = comp.display_name
        local eid = comp.getEntity().id
        self:onVisorConnected(comp.getEntity())

        -- ask all videos to send the recent frame so the new player gets it
        for _, video in ipairs(self.videoSurfaces) do
            video:sendLastFrame()
        end
    end
end

function App:onComponentRemoved(cname, comp)
    if cname == "visor" then
        local eid = comp.getEntity().id
        self:onVisorDisconnected(eid)
    end
end

function App:onVisorConnected(entity, name)

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

function App:now()
    return self.client.client:get_server_time()
end

function App:_timeForPlayingSoundNow()
    return self:now() + (self.latestTimeout or 0.05)
end

function App:addVideoSurface(surface)
    table.insert(self.videoSurfaces, surface)
end

return App
