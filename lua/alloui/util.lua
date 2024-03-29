local tablex = require("pl.tablex")
local allonet = require('alloui.ffi_allonet_handle')

-- http://lua-users.org/files/wiki_insecure/users/chill/table.binsearch-0.3.lua
local fcomp_default = function( a,b ) return a < b end
function table.bininsert(t, value, fcomp)
    -- Initialise compare function
    local fcomp = fcomp or fcomp_default
    --  Initialise numbers
    local iStart,iEnd,iMid,iState = 1,#t,1,0
    -- Get insert position
    while iStart <= iEnd do
        -- calculate middle
        iMid = math.floor( (iStart+iEnd)/2 )
        -- compare
        if fcomp( value,t[iMid] ) then
            iEnd,iState = iMid - 1,0
        else
            iStart,iState = iMid + 1,1
        end
    end
    table.insert( t,(iMid+iState),value )
    return (iMid+iState)
end

function table.merge(t, u)
    if u == nil then return t end
    for key, _ in pairs(u) do
        local left = t[key]
        local right = u[key]
        if type(left) == "table" and type(right) == "table" and not left[1] and not right[1] then -- treat arrays as values
            table.merge(left, right)
        else
            if type(right) == "table" then 
                t[key] = tablex.deepcopy(right)
            else
                t[key] = right
            end
        end
    end
    return t
end

local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' -- You will need this for encoding/decoding
-- encoding
function base64_encode(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

function gltf_node_transform(asset, nodename)
    local allom = allonet.allo_gltf_get_node_transform(asset.data, asset:size(), nodename)
    local m = mat4.identity()
    for i=1,16 do
        m[i] = tonumber(allom.v[i-1])
    end
    return m
end

return {
    getTime= getTime,
    base64_encode= base64_encode,
    gltf_node_transform= gltf_node_transform,
}
