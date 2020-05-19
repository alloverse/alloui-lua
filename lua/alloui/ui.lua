local modules = (...):gsub('%.[^%.]+$', '') .. "."

local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local vec3 = require("modules.vec3")
local mat4 = require("modules.mat4")
require(modules .."random_string")
local util = require(modules.."util")

class.View()
function View:_init(bounds)
    self.viewId = string.random(16)
    self.bounds = bounds
    self.transform = mat4.identity()
    self.subviews = {}
    self.entity = nil
    self.app = nil
end

-- awake() is called when entity exists and is bound to this view.
function View:awake()
end

function View:_poseWithTransform()
    local out = mat4.identity()
    mat4.mul(out, self.transform, self.bounds.pose.transform)
    out._m = nil
    return out
end

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

function View:setTransform(transform)
    self.transform = transform
    self.app.client:sendInteraction({
        sender_entity_id = self.entity.id,
        receiver_entity_id = "place",
        body = {
            "change_components",
            self.entity.id,
            "add_or_change", {
                transform= {matrix= self:_poseWithTransform()}
            },
            "remove", {}
        }
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

function View:onInteraction(inter, body, sender)
end

class.Surface(View)
function Surface:_init(bounds)
    self:super(bounds)
    self.texture = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsQAAA7EAZUrDhsAAAM6SURBVHhe7Zq9b9NAGIdfJ2lSqlYCNtQVhGBkKOIPQOJjQEgMTBUDYkDqVDb+BqZuwFKpCxJiQRVCZWBKF9S1c4QQXfgKH21omuD3cm+4nBz7fL472z0/Uvq6kXr277n37MZxsLuzOQSPqfHqLZUAXr2lEsCrtxgVcOHSTfayhY3xjVwG6aCuPhkNtbUasBqOzWpWcPxGOFX9AX8jxNTYmQTIwUVIAqJ7sDj+qdkafDsYwOeV6/xdgI/dfVhaf8+2s4rQEiC2YVR4Ed1uoH2IwWXOrL3hW/oiUgm4dvshdDodtp0UXEZVhEpwmSwilAXEtbsqccsCx5+fCeDX4TBVeBESkUZCooA07a6KLEJn1uNII2KqABvBZUQRpsITqssiUoCJdo+Dgj9YvgWt5gysPX/JfjctAUkSMSEAg9Nlx0Z4DE7X85X7d/i7/3EhQpYwFuBq1qOCi6CEqGu/CaK6AY9qeLJVg+89e7OOJAWXcdUNTIDN4Avzc3Dv7g22nZbNrTZ82duDH+Hk2OoG4wIoOJJ21qdhoxusCNBtd1VMijAqwHZwEZTQrAfw90j/P0bEiAAb7a5K1m7ILMDlrMehK0JbQFGCi5AERFUECdC6JVak8EiW46luivJaenS7oOoAXr2lEsCrd1xZPM2qtwK2P31l1VsBq0tnWfVWwKPL51itToL4Q/xU5xtVB/DqLZUAXo8FC031c9n4fgB9QYAnwrKfDBu15OPH4BefvWXbmJ11AG6IIspKfzD9zla3dzie9Xb79TjvxBIgEWXthmkdgMHPP303MdFE5DmgrCL2+5MdgMHxFRWciD0J0h99eFwvhYgTjdExyus8jsQnRAjxgYmi3RQlNjZesW+VkaTghLIAoqgi6Na4anAitQARkpGnCPE7gbThkUwCEJQwG669g/AE5FIEBp8L9/sn3K9OcCKzAMJlN+i2exTGBBA2RZgMThgXgKCEVj2A3pGZZYHB6bkhk+ERKwII6gZEV4SNWRexKoDQWRa2gxNOBBAqIro/f8P6i9GHFtvhEacCEJRAj7jIIlzNuohzAYTYDXkEJ3ITgJCEPIITuQooAsfqnqAOlQBevcVzAQD/ACwg7buhFwAGAAAAAElFTkSuQmCC"
end

function Surface:specification()
    local s = self.bounds.size
    local w2 = s.width / 2.0
    local h2 = s.depth / 2.0
    local mySpec = tablex.union(View.specification(self), {
        geometry = {
            type = "inline",
                  --   #bl                   #br                  #tl                    #tr
            vertices= {{w2, 0.0, -h2},       {w2, 0.0, h2},       {-w2, 0.0, -h2},       {-w2, 0.0, h2}},
            uvs=      {{0.0, 0.0},           {1.0, 0.0},          {0.0, 1.0},            {1.0, 1.0}},
            triangles= {{0, 3, 1}, {0, 2, 3}, {1, 3, 0}, {3, 2, 0}},
            texture= self.texture
        },
    })
    return mySpec
end


class.Button(Surface)
function Button:_init(bounds)
    self:super(bounds)
    self.selected = false
    self.highlighted = false
    self.onActivated = nil
    self.texture = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAIAAAAlC+aJAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAD8SURBVGhD7c/LCcJgFERhq7Qgy3CfRXoQXItNGYmEeMyQbEbuhYFv9T9gzun6fPR1HofGAdP6xgHz+q4By/qWAev1/QKwftIpANNnbQKwe9EjAKPXGgRgMVQPwNxfpQOwddPRgMv99mcYqiTABkOVBNhgqJIAGwxVEmCDoUoCbDBUSYANhioJsMFQJQE2GKokwAZDlQTYYKiSABsMVRJgg6FKAmwwVEmADYYqCbDBUCUBNhiqJMAGQ5UE2GCokgAbDFUSYIOhytEAfKvjUAD+lLIfgA/V7ATgdUEyAO/K2g7Ao8o2AvCiOAbgur6vANy18AnAaSPvABx1Mg4vbr0dVP2tGoQAAAAASUVORK5CYII="
end

function Button:specification()
    local s = self.bounds.size
    local w2 = s.width / 2.0
    local h2 = s.depth / 2.0
    local mySpec = tablex.union(Surface.specification(self), {
        collider= {
            type= "box",
            width= s.width, height= s.height, depth= s.depth
        }
    })
    return mySpec
end

function Button:onInteraction(inter, body, sender)
    if body[1] == "point" then
        self:setHighlighted(true)
    elseif body[1] == "point-exit" then
        self:setHighlighted(false)
    elseif body[1] == "poke" then
        self:setSelected(body[2])

        if self.selected == false and self.highlighted == true then
            self:activate()
        end
    end
end

function Button:setHighlighted(highlighted)
    if highlighted == self.highlighted then return end
    self.highlighted = highlighted
    self:_updateTransform()
end

function Button:setSelected(selected)
    if selected == self.selected then return end
    self.selected = selected
    self:_updateTransform()
end

function Button:_updateTransform()
    if self.selected and self.highlighted then
        self:setTransform(mat4.scale(mat4.identity(), mat4.identity(), vec3(0.9, 0.9, 0.9)))
    elseif self.highlighted then
        self:setTransform(mat4.scale(mat4.identity(), mat4.identity(), vec3(1.1, 1.1, 1.1)))
    else
        self:setTransform(mat4.identity())
    end
end

function Button:activate()
    if self.onActivated then
        self.onActivated()
    end
end

class.Speaker(View)
function Speaker:awake()
    self.app.client:sendInteraction({
        sender_entity_id = self.entity.id,
        receiver_entity_id = "place",
        body = {
            "allocate_track",
            "audio",
            48000,
            1,
            "opus"
        }
    }, function(response, body)
        if body[1] == "allocate_track" and body[2] == "ok" then
            self.trackId = body[3]
        else
            print("Speaker failed track allocation: ", pretty.write(body))
        end
    end)
end

class.Pose()
-- Pose(): create zero pose
-- Pose(transform): create pose from transform
-- Pose(x, y, z): create positioned pose
-- Pose(a, x, y, z): create rotated pose
function Pose:_init(a, b, c, d)
    if b == nil then
        self.transform = a or mat4.identity()
    elseif d == nil then
        self.transform = mat4.translate(mat4.identity(), mat4.identity(), vec3(a, b, c))
    else
        self.transform = mat4.rotate(mat4.identity(), mat4.identity(), a, vec3(b, c, d))
    end
end

function Pose:rotate(angle, x, y, z)
    self.transform = mat4.rotate(self.transform, self.transform, angle, vec3(x, y, z))
end

class.Size()
function Size:_init(width, height, depth)
    self.width = width
    self.height = height
    self.depth = depth
end

class.Bounds()
-- Bounds(pose, size)
-- Bounds(x, y, z, w, h)
function Bounds:_init(a, b, z, w, h, d)
    if type(a) == "table" then
        self.pose = a
        self.size = b
    else
        self.pose = Pose(a, b, z)
        self.size = Size(w, h, d)
    end
end

class.ScheduledAction()
function ScheduledAction:_init(delay, repeats, callback)
    self.delay = delay
    self.repeats = repeats
    self.callback = callback
    self.when = util.getTime() + delay
end

class.App()
function App:_init(client)
    self.client = client
    self.mainView = View()
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
    self.client:connect(mainSpec)
    self.mainView:setApp(self)
end

function compareActions(a, b)
    return a.next < b.next
end
function App:scheduleAction(delay, repeats, callback)
    local action = ScheduledAction(delay, repeats, callback)
    table.bininsert(self.scheduledActions, action, compareActions)
end

function App:run()
    while true do
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
        self.client.client:poll()
    end
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

return {
    View = View,
    Surface = Surface,
    Button = Button,
    Speaker = Speaker,
    Bounds = Bounds,
    Pose = Pose,
    App = App,
    Size = Size
}