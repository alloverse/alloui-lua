local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local Surface = require(modules.."views.surface")


-- Like a window resize widget. Drag to resize your view.
-- WIP
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

return ResizeHandle