local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local Surface = require(modules.."views.surface")



-- Button can be poked/clicked to perform an action.
-- set onActivated to a function you'd like to be called when the button is pressed.
-- set label to the string you want on the button
-- you can also set the button's default, highlighted and activated texture (see Surface
-- documentation for image format caveats)
class.Button(Surface)
function Button:_init(bounds)
    self:super(bounds)
    self.selected = false
    self.highlighted = false
    self.onActivated = nil
    self.label = ""
    self:setDefaultTexture("iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAG7SURBVHgB7Zu7TgJREIb/Q8sldIYOTLDV0kqBF8AHMNpYi1hLkNDLbktloi/AEwh2VlJLonQkViZgvc7ILlkPW3qJZ+ZLJmczS/N/O4duDCyCIKjQcUBVpyrCDcZhdYwx08RfUPA8VS9wH86Yj3KbKDwdd1Q7kAFPQ5Wm4S0VNtqQE57hrJwZhr5+kc6X+NvZ7BXdjofJ5Bnz+Tv+O3v7u2ien6BQ2LBfVVnANT0cRx0Of3R46kTwOJlsGje3vi3B5yuwHe/0rvrOhWcWlKnb8e12nQV8ufv3owe4yhNdaYtiCoJYJEy2KAFJqAAIRwVAOCoAwlEBEI4KgHBUAISjAiAcFQDhqAAIRwVAOCoAwlEBEI4KgHBUAISjAiAcFQDhqAAIRwVAOCoAwlEBEI4KgHBUAISjAiCcNQHZbBqSYAHTeKNc3oSr8PKUxZgFDOKdVvvMySnI5TKfm2MWY94aq2C5NLmCN8e8Xh+j4d/tDxlj8B3wxyxvlXDRaiStzZWizVGPjgZk4ZHkptTV2Ueq2mp1lh/oqFL5cJuAiqe9FmbG2kULV2kvsVyo/M2JCPBzTLH8sx9Q8GH8xQeQyFapUwYxYQAAAABJRU5ErkJggg==")
    self:setHighlightTexture("iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAEfSURBVHgB7ZvBccJAEAR7FQEh4AjsEJATgIyMIzAOhQjsDKwMrBCcwXm3JHgAX3hopqu27urqPtva02+CC1prm1x2WdusNctgmOs9IsabN7LxVdZHWz7V4+rUd5yaz+Ur6wUNahr6nIa/bj54Q6f5onqtnon8+utcf9GkrwnYo8uuBDyjy7aeQEOYDnEsAHEsAHEsAHEsAHEsAHEsAHEsAHEsAHEsAHEsAHEsAHEsAHEsAHEsAHEsAHEsAHEsAHEsAHEsAHEsAHEsAHEsAHEsAHEsAHFKwIguQwk4ostQmaENU2hSkacuIr5z84keh8oRq0Znf7Jez9HZ2uTSs/xJqIjggbn5OoirG1OUds8UqHzkRNwzvzgy/eyP85M/8w/NcyFcDaSY1AAAAABJRU5ErkJggg==")
    self:setActivatedTexture("iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAGeSURBVHgB7ZuhUsNQEEXv1pcpFhWHLAg86Q8UhWX4AsDgGOjgMG2/ACwo+gUg0FCLIgpLZ/iAsEuSTl8TCZ3pu3tmdl5mE3NPNnErWCLP8309DrT6WgniYFrWQESyxic0eEdrmMePZexUuaUKr8eT1g44sGlIdRpmrbJxCZ7whmW1zBB9+4meH8Htzwy4OAbeVdT3DGtPqr+08yGwldTumIA7vTiatyz84W4cwRdp61f+8LYsYWyfQDd48OY0vvCGZbKpDunbBORBqyuIFpuCl6+g1QITDZPNJaABFwByXADIcQEgxwWAHBcAclwAyHEBIMcFgBwXAHJcAMhxASDHBYAcFwByXADIcQEgxwWAHBcAclwAyHEBIMcFgBwXAHJcAMhxASCnLqDdARMmIAs62xEvj9nyVMjUBEyC1vVtnFOwsVlsjoX8CngMWrZVZdtVdVurReRvyoLvpcD9a9Pa3KDaHB3pcQIuRiJyxro6qyOO3nx11i700DnBGHFjK4I27b0yM2pLguUq7RWKhcpVTkSO/yND8bOfaPDnxRs/kt5D/NR/QkwAAAAASUVORK5CYII=")
end

function Button:specification()
    local s = self.bounds.size
    local mySpec = tablex.union(Surface.specification(self), {
        collider= {
            type= "box",
            width= s.width, height= s.height, depth= s.depth
        }
    })
    if #self.label > 0 then
      mySpec["text"] = {
        string = self.label,
        height = s.height * 0.8,
        wrap = s.width
      }
    end
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
        self:setTexture(self.activatedTexture)
    elseif self.highlighted then
        self:setTexture(self.highlightTexture)
    else
        self:setTexture(self.defaultTexture)
    end
end

function Button:activate()
    if self.onActivated then
        self.onActivated()
    end
end

function Button:setDefaultTexture(t)
  self.defaultTexture = t
  self:setTexture(t)
end

function Button:setHighlightTexture(t)
  self.highlightTexture = t
end

function Button:setActivatedTexture(t)
  self.activatedTexture = t
end

function Button:setLabel(label)
  self.label = label
  self:updateComponents({
    text = {
      string = self.label,
      height = self.bounds.size.height * 0.8,
      wrap = self.bounds.size.width
    }
  })
end

return Button