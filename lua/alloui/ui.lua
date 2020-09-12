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

function View:isAwake()
  return self.entity ~= nil
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
    local h2 = s.height / 2.0
    local mySpec = tablex.union(View.specification(self), {
        geometry = {
            type = "inline",
                  --   #bl                   #br                  #tl                   #tr
            vertices= {{-w2, -h2, 0.0},      {w2, -h2, 0.0},      {-w2, h2, 0.0},       {w2, h2, 0.0}},
            uvs=      {{0.0, 0.0},           {1.0, 0.0},          {0.0, 1.0},           {1.0, 1.0}},
            triangles= {{0, 1, 3}, {0, 3, 2}, {1, 0, 2}, {1, 2, 3}},
            texture= self.texture
        },
    })
    return mySpec
end

-- Set a base64-encoded png texture on a surface that is alive.
function Surface:setTexture(base64png)
    self.texture = base64png
    if self:isAwake() then
      local geom = self:specification().geometry
      self:updateComponents({
          geometry= geom
      })
    end
end


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
  self.texture = t
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

class.Label(View)
-- Label{bounds=,text=,lineheight=,wrap=,halign=}
-- Label(bounds)
function Label:_init(o)
    local bounds = o.bounds and o.bounds or o
    self:super(bounds)
    self.text = o.text and o.text or ""
    self.lineheight = o.lineheight and o.lineheight or bounds.size.height
    self.wrap = o.wrap and o.wrap or bounds.size.width
    self.halign = o.halign and o.halign or "center"
end

function Label:specification()
    local mySpec = tablex.union(View.specification(self), {
        text = {
            string = self.text,
            height = self.lineheight,
            wrap = self.wrap,
            halign = self.halign
        }
    })
    return mySpec
end

function Label:setText(text)
    self.text = text
    self:updateComponents(self:specification())
end


class.GrabHandle(Surface)
function GrabHandle:_init(bounds)
    self:super(bounds)
    self.texture = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsIAAA7CARUoSoAAAAP+SURBVHhe7ZsLjpswEIZDol6k6lF6yp6lB2jVK1Q9x0ptROe3Z/BrbA8EdoHk0zoQM29sx9llh2+/fo6XHgMfq5K4IEIr0zONa/0MVO7jeLnyuc5A1sVB4SSOqhXhg4jpWpILkwc3yk8vgBilCukO0PmA5yVIIVaudSgA7jZAXlUnknQssDwir2nTn6RWrnsoAO42UOMJXkv/yyPymjb95V7atNcAcTuI2GC8X8ehUQAkz+nK6Cj42II85JvXt0YBGuaneozhVMVfhaW4rUXbt0akQWve2/1fbwpUcFmUyZX4XkjGzQ5bdUrzNEvI1phGWf8YzLAmtz5s1bnSo7BDtmACDWbp+Ol2sxVgveR2sIhy8pLUsikwh8gZTvRiSm96dXGxZihuUgCXBl6wucJqW/Ui1ZGI08jTcsyAFb211GaO6cvQ9z+/+ewYfP38hc/6dEfA0ZIHc2Lefg3YOZUCnG/LWyMUABlPq4FfrdE1Zz7thTkx0yL4g3KlVCXjCKUr4ArWlFgN58qf2kBGpGTRoRHACRR51KYBh+Os6xKPkYVNRc52sA1YcEZY2RoQO88D4aM7aXiofnO0QrZj86Zb6WWGSNAaBRdgZJ+xZ0YsKZcKIIuAH8Ua/QQp+Bq0kdAiQS5AXDvPlIYpH9ZeIfdNkSSjQmRTIOBl/TpQa4H03f7Iby9DYZ98K4zU2jenOgKEY2+F+yPziiLtfQCvh0zs0K54TebASaqhp+F7ka+0dApIb8RRt8JZGlV4EaSf1oZDfrFxUOLR4LPAq++d9gFq8tKXJK8JfjxIJ040BhFL8wRJ5VMAF1lUtcidNW8b4dyxT+0WpAmW1MINBZjuMo7BE85U5Za3DXDu2GctmZxYrhZuKMBVvv1FanQKxUdyXRJsE46ppOy1xB2NAFGwqNmxWjN7JcGkWNMbcwkTXr8V5mOVY2+FO9DHeyjAshF0bGjhT9aAZ6Q7BY66FbZiWgTPTHcEnBe/6D1HAdQF3g/85yhAY5I/8RTwPH0BXlthPlY59VaYeK0BfHxOaPJ3C3DqrTDtD15bYT5W8Zuo3kPRdv7e71PbA90C+MSXPjQVaXEF8XyutPdHnoMIbLwIRuNmaP+pHW17sucgyOk7fgr4adRqFhYXKvvLlrMzGh+XN0cHuY1vZRqKJTCSQUzZoztes/d/g4I1KchZYlqNTmDurpNMI6Z3nAIb0Mof17K7XmKdAjvD5YbGo9u/ZJhGYj4FMGQKRc0SeTQ56KH56wOVuJltKCMiLQAECplKeV03XqzeNXJ/bCsyicuJiBVSKiLLPgnAzCmQG8D7pZskDbYUGYSHMuwIbZ6jj5Qscc0sgG4yCVCp8jZwhpo/cwyXy3+J0TAitxbCpAAAAABJRU5ErkJggg=="
end

function GrabHandle:specification()
    local s = self.bounds.size
    local w2 = s.width / 2.0
    local h2 = s.depth / 2.0
    local mySpec = tablex.union(Surface.specification(self), {
        collider= {
            type= "box",
            width= s.width, height= s.height, depth= s.depth
        },
        grabbable= {
            actuate_on= "$parent"
        }
    })
    return mySpec
end






class.ResizeHandle(Surface)
function ResizeHandle:_init(bounds, translationConstraint, rotationConstraint)
  self:super(bounds)
  self:setDefaultTexture("iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAL7SURBVHgB7ZvPaxNBFMe/W7zZlp6U3FIhngRFQXrSpneJN7WIXlIQD9Z6FEsNBb2Z5FKl7UGoP4/VP8DWkwrGQG8GNLeCJ6H1vL6X7JbNZNvMbmZ3k535wDCb2ZA3329mNrszeRYEbNuepuoqlQKVLNJB3Skly7Kavu8g4RNUynb6YY0Trm7LFU/VJyrnoAc8GvI0Gv6OOA1L0Ec8w1pZMyz69rNU//ae3d39g+VSBY3GL+zt/cOwc+nyFBYeFJHJnBRP5dmAl3Rw221h8bdu3kuFcC+jY8ex8aoqmlDlKXDW21J+tpo68cw+aVouVcXmAhvQMfc/b39FWvlJU1ogOwKN2PcZ2VoZ4IcxAJpjDIDmHENCfPn2seP11MUrSAIzBaA5xgBojjEAmmMMgOb0bcD5C2eQFCpi92VAce4GVp4/bdVxoyp2aAM4cHFu1jmejdUElbFDGeDtgMu16wWM0cJj1GQyJ1qxOvsT3oTABviJ50XUu3cexrKYyqvWfrHCmhDIgKPEN7oXHCODY6kyQdqAQRHvosoEqfUAP/EMz/mN11WZjwj8vC+uFwTB7ev62tue7+05Ag4TP+jIjgSJKWBheOnd954GrK+9kRpKgwb3mfveC6lrgPtB4pCK8iIoc83I5U5h5cWTrvsPWfGM9K+A30jgwNwB7kjcqBDPBLoPGBQTVIlnAt8JHmUC36ZGzagTS4V4JtSzgJ8J7999aN2mRg3v8HKszv6EE8+Efhr0mtBPB5KO3dfOEAeufd9BrbaDuFEVu+8VoSTEq4xt1gShOcYAaI4xAJpjDIDmJPYfoaT+EyRipgA0xxgAzTEGiA1x7PAOEmxA09uQxApvXHDylECdDdj0tiwu3U/lKBgfH21ljgnUOWtsGu2kyQN4cbNSXsX2VnL5Q5alZkuOv8zc6Uk8Wpz3S5ubdDNHK1TNQy8qZPKCrqmzP6jMHKTO8gFVeSpym/3Di02FR/uMo7l7/9hJpX2MdkJlnCPCRnQ00b7Yb5LwLe+J/7CAJp4/k5mLAAAAAElFTkSuQmCC")
  self:setHighlightTexture("iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAJuSURBVHgB7Zu/SyNBFMe/E667E6zusPMO7rrjDgWxNPb+6PyBdgpqY2+jNrZqo4XW/iiDf4CWIhgDdgqaLmglqPX6XrIrSVzd2d3Z3Zg3HxhmDUve+359M5nZZBSacBxngLpRaiPUutEelNy2qpQq+95BwjuprTvtD2vs9HQrTzx1x9T+QwZcDXmqhoec+8Iy5IhnWCtrhqL/fjf1t5BJnitgBXIZZQP+QS4jPAQcCCYH4VgDIBxrAIQj3oAvyIj+vqGGv0/PjpAFdghAONYACMcaAOFYAyCc2AYUi5fIChOxYxmwu7OPhbmlap82pmJHNoAD7+7sudd7qZpgMnYkA+oT8Dg8KODx8RlJU6ncV2M15hPdhNAG+Inv6PiKre21ap80XV3ffWNFNSGUAR+J//3nF9KCY5kyQduAVhHvYcoErecBfuIZHvPTU4s6bxF6v9/8vCAMXq4zsxOB9wZWwHviWx3dStAYAp/5e5Pg3AMNmJmd1CqlVoNz5tyD0JoDvDdqLqlvNAFtJzQJ6swZ11c3WJhferP+0BXPaH8K+FXCEwWepwQ4kbQxIZ4JtQ5oFRNMiWdCrwQ/MqFSuUPSsGhT4plIewE/E8bHh2mZ+gNJwwufMYrVmE808Uzk3WC9CXESyDp27B9IFM8v0dP7F2Ex8c1Q1Nj1xH4iFDeBrGPbZ4IQjjUAwrEGQDjWAAjH/lQWwrEGQDjWAAjHGkCtDLmU2IAC5FLihdAAaocmJfIzp5Q6oYtNyGODzxFLPTp7QW3w9egsX1CXR/tXAu97NuCK5xfUmztqR2lXUDtQmWZFJLkpK6M22RfcIf/KCyTc+68cKnCQAAAAAElFTkSuQmCC")
  self:setActivatedTexture("iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAALFSURBVHgB7Zsxb9QwFMefK1ZQWZlu69giwd7rFygTC0gIsdCJY2FDzYmNpb2pXRAMMMBEPwEdGBFtx069qWsr9QOk798k1TlxGyfxxWmef5KVkxPJ/v/vxUmebUU54jhe5cMzLutcBtQPDtMyVkpNjVew8EUuW3H/gcbFTLfKxPPhD5cVkgGiYcjRcL6QVmySHPEAWqGZFP/7Az6eaKdPp0QfXxMds1EX53TnGfKQ9mGL6NGgcAYGfOMfr66rIP75434In+U+3+W/DvImTHALLGsXfh71TzyAJkS1zjoiINaqlhX1FkTB3zOtaoEkYYhsWQYYCAaQcIIBJJx75Isj/enr6/EbbgESTjCAhBMMIOEEA0g4zQ14skrecNB2MwPecl7xCyeTNzapdRy1Xd8AdGAjSn9H7ZrgsO16Bsx2IOPFKEk5zRskNV+O9LoGJlQ3wCQeqaY3w3aSqcham9qqaUI1A24TjzmEtkBbjkywN6Ar4jMcmWCXDzCJB9lkgw1Vv/fz+YIqwASwMy69tDwCbhLfdSwjweIWuMsTJeV9LzdgN7IKpc6xy33eiUovsxsDYALIh9Q8B0GbMWNpJXkbzL9/WIoH9k8BUySgYXRgycPSAgfiQbX3gK6Y4Eg8qP4meJsJxQUI7snaciAe1PsWMJnwY5K8ps4bjDvfJ3pdTfGg/tfgrAkNOuC77eYLJJCU+LdPlXExM1Sn7Vy7/laI+Joay7UbcoIknGAACScYQMIJBpBw/K0R6siS3HALkHCCASScYEChpo0Z3g4BA6ZajY8Mb1tg85TOIQzY06o+fe1nFDx4mOwc07ky4LdWhcwuJjyLbrWLUm4KhD/lyZuf/01Z63G2c3SbD+9IFttKqfdSt85iTn/teussfvCB44Qm1G+QEUW0r6Wai/PH6VbaiJINlW1GRIMVEaVMKRns91j4/uyJS1ey1zLpqgLpAAAAAElFTkSuQmCC")
  self.selected = false
  self.highlighted = false
  self.onActivated = nil
  --self.constrainedAxes = axes and axes or {"x", "y", "z"} -- What's this "and/or" situation? Setting a default if 
  self.translationConstraint = translationConstraint
  self.rotationConstraint = rotationConstraint
end

function ResizeHandle:specification()
  local s = self.bounds.size
  local w2 = s.width / 2.0
  local h2 = s.depth / 2.0
  local mySpec = tablex.union(Surface.specification(self), {
      collider= {
          type= "box",
          width= s.width, height= s.height, depth= s.depth
      },
      
      grabbable= {
        translation_constraint= self.translationConstraint,
        rotation_constraint = self.rotationConstraint
      }
  })
  return mySpec
end

function ResizeHandle:onInteraction(inter, body, sender)
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

function ResizeHandle:setHighlighted(highlighted)
  if highlighted == self.highlighted then return end
  self.highlighted = highlighted
  self:_updateTransform()
end

function ResizeHandle:setSelected(selected)
  if selected == self.selected then return end
  self.selected = selected
  self:_updateTransform()
end

function ResizeHandle:_updateTransform()
  if self.selected and self.highlighted then
      self:setTexture(self.activatedTexture)
  elseif self.highlighted then
      self:setTexture(self.highlightTexture)
  else
      self:setTexture(self.defaultTexture)
  end
end

function ResizeHandle:activate()
  if self.onActivated then
      self.onActivated()
  end
end

function ResizeHandle:setDefaultTexture(t)
self.defaultTexture = t
self.texture = t
end

function ResizeHandle:setHighlightTexture(t)
self.highlightTexture = t
end

function ResizeHandle:setActivatedTexture(t)
self.activatedTexture = t
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
    return self
end

function Pose:move(x, y, z)
    self.transform = mat4.translate(self.transform, self.transform, vec3(x, y, z))
    return self
end

class.Size()
function Size:_init(width, height, depth)
    self.width = width and width or 0
    self.height = height and height or 0
    self.depth = depth and depth or 0
end

class.Bounds()
-- Bounds{pose=,size=}
-- Bounds(pose, size)
-- Bounds(x, y, z, w, h)
function Bounds:_init(a, b, z, w, h, d)
    if type(a) == "table" then
        if type(b) == table then
            self.pose = a
            self.size = b
        else
            self.pose = a.pose and a.pose or Pose()
            self.size = a.size and a.size or Size()
        end
    else
        self.pose = Pose(a, b, z)
        self.size = Size(w, h, d)
    end
end

function Bounds:rotate(angle, x, y, z)
    self.pose:rotate(angle, x, y, z)
    return self
end

function Bounds:move(x, y, z)
    self.pose:move(x, y, z)
    return self
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

function App:_run()
    while true do
        self:runOnce(1.0/40.0)
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

return {
    View = View,
    Surface = Surface,
    Button = Button,
    Label = Label,
    GrabHandle = GrabHandle,
    ResizeHandle = ResizeHandle,
    Speaker = Speaker,
    Bounds = Bounds,
    Pose = Pose,
    App = App,
    Size = Size,
    util = util
}