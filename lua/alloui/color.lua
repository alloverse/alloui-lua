--- An RGBA color.
-- @classmod Color
local modules = (...):gsub('%.[^%.]+$', '') .. "."

local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')

class.Color()
function Color:_init(r, g, b, a)
    if g == nil then
        local hexstring = r
        r = tonumber(string.sub(hexstring, 1, 2), 16) / 255
        g = tonumber(string.sub(hexstring, 3, 4), 16) / 255
        b = tonumber(string.sub(hexstring, 5, 6), 16) / 255
        a = tonumber(string.sub(hexstring, 7, 8), 16) / 255
    end
    if a == nil then
        a = 1.0
    end
    self[1] = r
    self[2] = g
    self[3] = b
    self[4] = a
end


function Color.alloLightPink()
    return Color("E7AADAFF")
end
function Color.alloDarkPink()
    return Color("D488C6FF")
end
function Color.alloLightGray()
    return Color("C8D0E0FF")
end
function Color.alloDarkGray()
    return Color("A9B6D1FF")
end
function Color.alloLightBlue()
    return Color("CDEBFAFF")
end
function Color.alloDarkBlue()
    return Color("B98FDAFF")
end
function Color.alloLight()
    return Color("FAFFFAFF")
end
function Color.alloDark()
    return Color("0C2B48FF")
end

return Color