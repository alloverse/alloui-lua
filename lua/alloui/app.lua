local modules = (...):gsub(".[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local util = require(modules .."util")



-- Schedule work to be done later
class.ScheduledAction()
-- delay: in how long (in seconds) should callback be called?
-- repeats: should it then be rescheduled with the same delay again?
-- callback: function to be called with no arguments
function ScheduledAction:_init(client, delay, repeats, callback)
    self.delay = delay
    self.repeats = repeats
    self.callback = callback
    self.when = client.client:get_time() + delay
end

-- Represents the Alloverse appliance. Mediates communication with
-- backend, and maintains the runloop.Create one of these, configure it,
-- connect it and run it, and you have an alloapp.
class.App()
App.ScheduledAction = ScheduledAction
function App:_init(client)
    self.client = client
    self.mainView = View()
    self.running = true
    client.delegates.onInteraction = function(inter, body, receiver, sender) 
        self:onInteraction(inter, body, receiver, sender) 
    end
    client.delegates.onComponentAdded = function(cname, comp)
        self:onComponentAdded(cname, comp)
    end
    client.delegates.onDisconnected = function(code, message)
        print("DISCONNECTED", code, message)
        self.running = false
    end
    self.scheduledActions = {}
end

function App:connect()
    local mainSpec = self.mainView:specification()
    local ret = self.client:connect(mainSpec)
    if not ret then
        error("Failed to connect")
    end
    self.mainView:setApp(self)
    return ret
end

function compareActions(a, b)
    return a.next < b.next
end
function App:scheduleAction(delay, repeats, callback)
    local action = ScheduledAction(self.client, delay, repeats, callback)
    table.bininsert(self.scheduledActions, action, compareActions)
end

function App:run(hz)
    local a,b = pcall(function() self:_run(hz) end)
    print("Exiting", a, b)
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
  local nextAction = self.scheduledActions[1]
  local now = self.client.client:get_time()
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

function App:onInteraction(inter, body, receiver, sender) 
    if receiver == nil then return end
    local vid = receiver.components.ui.view_id
    local view = self.mainView:findView(vid)
    if view then
        view:onInteraction(inter, body, sender)
    else
        print("warning: got interaction", body[1], "for nonexistent vid ", vid, "eid", receiver.id)
    end
end

function App:onComponentAdded(cname, comp)
    if cname == "ui" then
        local vid = comp.view_id
        local view = self.mainView:findView(vid)
        if view then 
            view.entity = comp:getEntity()
            view:awake()
        end
    end
end

return App