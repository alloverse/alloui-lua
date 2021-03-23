--- Navigation stack: pushes and pops [views](view) to drill down a hierarchy of UI.  
-- Includes a back button to allow navigation.
-- @classmod NavStack

local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local vec3 = require("modules.vec3")
local mat4 = require("modules.mat4")
local Bounds = require(modules .."bounds")
local Size = require(modules .."size")
local View = require(modules .."views.view")
local Button = require(modules .."views.button")
local Base64Asset = require(modules.."asset.init").Base64

class.NavStack(View)
NavStack.assets = {
    back = Base64Asset("iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAABHNCSVQICAgIfAhkiAAABKNJREFUeJzlWmtPG0cUPWNsp/gRwC8akUaRQgkkSNDwaJoAVWqXKFGVquq/6/+IDY4DRA0tFpBWQKtAiAlqQakxNvgRx47t7YcU1Zi1Pa+1kfdI+8XeO/ees3fuzJ1d8tNyWIFOEYpsw9DsIJqFUGQbAPQpwAl5QIcClJMHdCZAJXlARwKokQd0IkA18oAOBKhFHmhxAeqRB1pYABryQIsKQEseaEEBWMgDgJHHydt0isdMc2xE/2G24RKgKtTaKiLVg3TImwLVekrKXtPyOoK2d++khUMLOQLUI1lHnI7VF3AHQ/D4Z0EKBZX7tOvYG1cEFZWrVIJzbgGd4WVAUWCORuEKzZ29D0TdXgKatgqQfB7dj/2wvdw89bslsgPH80W6QSSIILcI0jpNpeD2B2COJ1T/t69voGCzITk8VH8wBUKFVlwAxqdgPjiAJzCDtkztgte1FEbRakXm816B4OpDTABG8pbdXbiCIfVCd2ZsBc65eRQt7Xjf08MXHwUaVgPs6xtwB6pU+SogpRI8M0GYEkeaxdWQGtC1+Csurq1x2WYv96Bgt0mO6H9wCUBbd0ihAFfoKSw7b3jcIDk8hMRXt7lsaSGWAQRV60BbNguPfwbmaJR5WMVgQHziLtI3bwiFRwNNpoA5kYD7cQDGFHvTVDKZEJv2IXvligaRnYX0VeCTvT24Z5/AkMsxD1e0WBB9+AB5t4veSLDZ4hdAhbxtcwuOhWcgpRLzcHmnE9GHD1C0WemNJHSacqaAoqBz9QU6Vla5GpfsZ5cRuz+NkskkJRwWCAtASiU45p/BtrXFZZ8a6EdiahKKoTltiZAAhlwOntkgLuztsxsTgsSX40h+McznXNJBi5AA1lfbXOQVQnDo8yLTe03EvRTw5x0BUoM3udZqoihcS6QWEJ54h5MTyF69ymzXuRRG58qqqHthiAlAABCCg2+9yHs8zOYdyyvoWgrz+T4vJ0IKARSjEQfTPihG9pJy8bff4Vj8RdNzv1qQtvYU7Hbs//gD13JmX1uH8+fnskJhgrAApOzBFRwORB99BxD2Ncr2x59wzi+wZYKEpBETQCWA95cuIebzIvdpN/NwtpebcD2d49pK80KT7Vem9xrefv+Ia523vtqG60mIXgTBLNBu/2kwIObzInO9j9nUEtmBezYIFIsaBHYa2m7ACUHsm3tIDfQzm7a/2YUnMMN0hsgDLgFYS1z86ymkBgeZ/bT/9Te6/QEYPnxgtqVFY1owQhCfvIvkEMWLjgpc2NuH5XVEg6A+QnwnyIDEnds4HrnFZHM8Nop0/3U2RwwQzwBGEY7Gx3A0PkZ17/HYKI5GR6T6r4ScKUAqrjo4Hrn18bi7xoaJirwEaFMD/hOilhbJ4SHEJ+6oikBNXsKhiKZFUKnMjIoMSQ0O4nBq8pRNo578CZpzEFcmQvrGAA699wBC2MifhyMxIZS9VUr39SHvciPv6KK3lYTmCQCcIpJ3UpKXjJb7UJIVXBnA80HieQVzBrB+inrewSRAq5EHGARoRfIARQ1oVeInqJkBrU4eqCGAHsgDVQTQC3lARQA9kQfKiqDeiJ/AAOiXPAD8C3aGgnjWH4zQAAAAAElFTkSuQmCC")
}

---
--~~~ lua
-- navStack = NavStack(bounds)
--~~~
--@tparam [Bounds](bounds) bounds The NavStack's bounds.
function NavStack:_init(bounds)
    self:super(bounds)
    self.stack = {}

    self.backButton = Button(Bounds{size=Size(0.12,0.12,0.05)}:move( 
        -bounds.size.width/2.0,
        bounds.size.height/2.0,
        0.025
    ))
    self.backButton.onActivated = function()
        self:pop()
    end
    
    self.backButton:setDefaultTexture(NavStack.assets.back)
end

--- Returns the item at the bottom of the stack.  
-- Does not remove the item from the stack.
--
--@treturn [View](view) The item from the bottom of the stack
function NavStack:bottom()
    return self.stack[1]
end

--- Returns the item at the top of the stack.  
-- Does not remove the item from the stack.
--
--@treturn [View](view) The item from the top of the stack
function NavStack:top()
    return self.stack[#self.stack]
end

--- Adds an item to the top of the stack
--
--@tparam [View](view) view The view to push
function NavStack:push(view)
    local oldTop = self:top()
    table.insert(self.stack, view)
    view.nav = self

    if oldTop then
        oldTop:removeFromSuperview()
    end
    self:addSubview(view)

    if #self.stack > 1 and self.backButton.superview == nil then
        self:addSubview(self.backButton)
    end
    
    -- todo: animate :P
end

--- Returns the item from the top of the stack.  
-- Removes the item from the stack.
--
--@treturn [View](view) top The item at the top of the stack
function NavStack:pop()
    local top = table.remove(self.stack)
    -- todo: animate :P
    top:removeFromSuperview()
    top.nav = nil
    if self:top() then
        self:addSubview(self:top())
    end
    if #self.stack < 2 and self.backButton.superview then
        self.backButton:removeFromSuperview()
    end
    return top
end

function NavStack:popAll()
    while self:top() do
        self:pop()
    end
end

function NavStack:popToBottom()
    while #self.stack > 1 do
        self:pop()
    end
end

return NavStack