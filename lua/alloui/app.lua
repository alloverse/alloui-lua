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
function ScheduledAction:_init(delay, repeats, callback)
    self.delay = delay
    self.repeats = repeats
    self.callback = callback
    self.when = util.getTime() + delay
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
    self.scheduledActions = {}
end

function App:connect()
    local mainSpec = self.mainView:specification()
    local ret = self.client:connect(mainSpec)
    self.mainView:setApp(self)
    return ret
end

function compareActions(a, b)
    return a.next < b.next
end
function App:scheduleAction(delay, repeats, callback)
    local action = ScheduledAction(delay, repeats, callback)
    table.bininsert(self.scheduledActions, action, compareActions)
end

function App:run()
    pcall(function() self:_run() end)
    print("Exiting")
    self.client:disconnect(0)
end

function App:_run(hz)
    hz = hz or 40.0
    while true do
        self:runOnce(1.0/hz)
    end
end

function App:runOnce(timeout)
  local nextAction = self.scheduledActions[1]
  local now = util.getTime()
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
    view:onInteraction(inter, body, sender)
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