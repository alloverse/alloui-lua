--- An Asset created from a Base64-encoded string.
-- @classmod Base64Asset

local class = require('pl.class')
local Asset = require ('alloui.asset.asset')

Base64Asset = class.Base64Asset(Asset)

---
--
--~~~ lua
-- my_asset = Base64Asset(base64)
--~~~
--
-- @tparam string base64 A Base64-encoded string representation of an asset
function Base64Asset:_init(base64)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' -- You will need this for encoding/decoding
    base64 = string.gsub(base64, '[^'..b..'=]', '')
    local data = (base64:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
            return string.char(c)
    end))
    self:super(data)
end

return Base64Asset
