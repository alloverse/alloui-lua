--- A window resize widget.
-- Grab and move to resize your view from its center point.
-- @classmod ResizeHandle


local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local Surface = require(modules.."views.surface")
local Base64Asset = require(modules.."asset.init").Base64


class.ResizeHandle(Surface)
ResizeHandle.assets = {
  default = Base64Asset("iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAQAAAAAYLlVAAAAoklEQVR42u3WPQoCMRCG4SAp9gQSJOWWFpZRLLz/Fay33SuMYBEShcTCyRB4n+6r8kH+xjkAfyAXSbLkdK5SKpOOsN3kkZc5PlOR4n4vkpLTdS2WCVWKVVLiq2VaiQpUeCfN+/BLhaT7JnQquKj/LJrsPhXmqjDulza5hp0KLoofO6t87v5h/LhkcgCp0KxgNTqbXMOvCiN+QwAAAAAAgNm8ADLo6BHvQOAJAAAAAElFTkSuQmCC"), --  iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAMzSURBVHgB7Zs/TFNBHMe/j7gJhM2wFZKyGY0mhkkpjNXgKjG6FCMMAm4aK9YmjLZdrAEGE43ORDsSqZOaqE3cJNFuJE4m4Fzv99ojz6N/ctzdA+/uk1ze670m5ft9vzvufncXQKDRaEywy1VWpllJwA5qrZILgqDe9htM+BArhYb9kMYhrjvg4tnlHStn4QYUDSkWDb/7WhXLcEc8QVpJMwL29hPs+jP6dGfnF/K5Ira3f2B39w/+dy5eGsfS3QyGh0+Jj1JkwHN2c5PXkPgb1+9YITxK/8BJvHhZEk0oURM4E60pPFm1TjyxxzTlcyWxepoM+Kftv69+hK18Z01aINEHh9hrE9lOGdAObwAc5wQk+fDpjdT3xy9cgQqmf883AVjGABvwyGCdAbKDOOk+oBv5x0VU3m5CJ2KbTiZH8fTZivSb7oTWCMg+XET68hRMoVs8ob0JmDLBhHhC2QCaNovoNqGT+PW111BF2YBKZdOoCd3Er6+9gipamoApE0yLJ7T1AbpNiEM8obUT7GRCZnZGuvOiFJZp8QSlxBrRCtWxO5FOTyG7vBjeU4pt/va98CoDpbDK5RUkx0bDz7rEi3MLrQMhDkUCkbk1cyjxBCUv5ubuhyZUWZZK95vnGImA44wYAX42CMfxBsBxvAFwHG8AHMcbAMfxBsAQ4Xy+rJ7DM51oNWIAT2acO39ayQQu3qQJymuDvfL2NJ8nE+bZ1FZm0UIUTZ8Jcd2h19/TC60R0CmNRfN52RWbL5+/HagzEQnaDNCdwzOdbeZoMcBUAjMOE5RTYqaztzy9xnOMHN4nqKIcAXGkrrtFgirKBsSRuiY6maCK1v8CpsRzTJigNS2emb0Wlihx7xGSxW+RgWUc6RaZOBHWcw6NtAFxrxyZ/j2fD4DjeAPECt27sI47ZEA9WkGTG1uhw1MCNTJgI1pDsy4bo2BwsD/cdiNQow0SE2gemtyHdnQUC6uobh3d+aEgCKADepnJsRE8yC60OzY3wk+O0gxjAW5RZCYvuXp09isrk/tHZ+mGXVKslGA3NH6maJ9sacaBhtY6SvsIzQOVcUaEnsF9e+podvYbTPhW9MFffPRLow5rPaEAAAAASUVORK5CYII=
  hover = Base64Asset("iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAQAAAAAYLlVAAAAqElEQVR42u3WvQ2DMBCGYVdUDMAqaVNRpfIYbJEBGOOqVAzgPahTs8LRIRskSJHzCel9uq/yJ/nvQgDwBzqqaLeld5EkTzb670fTtsxzlizFZcqSkddjyJbpixSLZKQtljlLVKDCpEnF8j78UkFs34SLCiHaP4suu0+Fe1Wo90u7XMOLCiFqW3dW2e9+U39ccjmAVDit4DU6u1zDQ4UavyEAAAAAAMDdrGEYQpwDzN6CAAAAAElFTkSuQmCC"), -- iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAKlSURBVHgB7Zs/TBRBFMa/udgZEioNHZpQGg2JYufdaSfKdUZiZSBBCmNNogImlh42xgit9gTsNFoaG6+VC3AVoST8qYd5e7uELLd3zM28Jdk3v2Qyd5vN3n3fzJvdebOjkEJrXTZVzZQJU4ZRDBpxWVBKtTqeYYQPmlLXxYc0Dia6VSLeVL9MuQUZUG+omN6wV4oPvIUc8QRpJc1QpvWHTb0NmVSoB8xDLjUy4CbkMkEhoCGYEoQTDIBwxBtwCZbcvfPI6vw/f9fgAvfvhRBAwTg4OLI6v3AGDAxctjrfegzoxus3r/Bw/D58ko7p5sYWZl/MWbd0Fl57wLvFJXxf/wkufIsnvIcAlwkc4glnA6jbp/FtQpb4qemncMXZAIp5ThO6iZ+anoQrXkKAywRu8YS3McC3CXmIJ7wOglkmrCx/sx686h9W2MUTLAkRanFqeWJo6Ao+fX5v6qs2l4jEz87Modncir5ziI/QTKyv/dC1x8/1zs6u7pf9/UP9bPKlXv7yVXMRUmIQTjAAwgkGQDjBAAgnGADhBAMgHDYDovn8jHsOjzvRyjIb3Pi/qR9Un+ix2+PRbI5mdf2wuFCPrkGFZpccWM8G02t158nbj4xcj3ICNosWnVq+07pDr//TC68hkJXGulces16xGR29ceYYRzh4M8B3Do8725zgxQCuBGYeJjivDXJnb5OYT3KMCenv/eI8CFJs55G9PZ1o7Ubug2Ae4omscHDF612ALXUdw2GCcwj0IrwjlDPhFZmLfEUmT5RS8EFYGYJwggEQTjDAlBbk0iADViGXBt0Gy2hvmpTItZJ5oPhtPnyEPJZoH7HUrbP/TKmebJ2lD6aqoPg9gZ56KatSjTXjzAO1bm+lnUd7Q2WePYLzkbyF9mC/Gof8CcdhjhrmlP2kYgAAAABJRU5ErkJggg==
  --active  = Base64Asset("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"),  
}

--- 
--
--~~~ lua
-- resizeHandle = ResizeHandle(bounds, translationConstraint, rotationConstraint)
--~~~
--
-- @tparam Bounds bounds The ResizeHandle's bounds.
-- @tparam table translationConstraint Only allow the indicated fraction of movement in the corresponding axis in the actuated entity’s local coordinate space. E g, to only allow movement along the floor (no lifting), set the y fraction to 0: `{1, 0, 1}`.
-- @tparam table rotationConstraint Similarly, constrain rotation to the given fraction in the given euler axis in the actuated entity’s local coordinate space. E g, to only allow rotation along Y (so that it always stays up-right), use: `{0, 1, 0}`.
function ResizeHandle:_init(bounds, translationConstraint, rotationConstraint)
  self:super(bounds)
  self:setDefaultTexture(self.assets.default)
  self:setHoverTexture(self.assets.hover)
  --self:setActivatedTexture(self.assets.active)
  self.selected = false
  self.isHover = false
  self.onActivated = nil
  self.translationConstraint = translationConstraint
  self.rotationConstraint = rotationConstraint
  self.hasTransparency = true
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
      },
      cursor= {
        name= "resizeCursor"
      }
  })
  return mySpec
end

function ResizeHandle:onInteraction(inter, body, sender)
  View.onInteraction(self, inter, body, sender)
  if body[1] == "point" then
      self:setHover(true)
  elseif body[1] == "point-exit" then
      self:setHover(false)
  elseif body[1] == "poke" then
      self:setSelected(body[2])

      if self.selected == false and self.isHover == true then
          self:activate()
      end
  end
end

function ResizeHandle:setHover(isHover)
  if isHover == self.isHover then return end
  self.isHover = isHover
  self:_updateTransform()
end

function ResizeHandle:setSelected(selected)
  if selected == self.selected then return end
  self.selected = selected
  self:_updateTransform()
end

function ResizeHandle:_updateTransform()
  if self.selected and self.isHover then
      --self:setTexture(self.activatedTexture)
  elseif self.isHover then
      self:setTexture(self.hoverTexture)
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

function ResizeHandle:setHoverTexture(t)
  self.hoverTexture = t
end

-- function ResizeHandle:setActivatedTexture(t)
--   self.activatedTexture = t
-- end

return ResizeHandle
