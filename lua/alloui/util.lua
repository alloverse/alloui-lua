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

local ffi = require("ffi")

ffi.cdef[[
    typedef long time_t;
    typedef int clockid_t;

    typedef struct timespec {
            time_t   tv_sec;        /* seconds */
            long     tv_nsec;       /* nanoseconds */
    } nanotime;
    int clock_gettime(clockid_t clk_id, struct timespec *tp);

    // windows
    typedef long clock_t;
    clock_t clock( void );
]]

local base = nil
function clock_gettime()
    local pnano = assert(ffi.new("nanotime[?]", 1))

    -- CLOCK_REALTIME -> 0
    ffi.C.clock_gettime(0, pnano)
    if base == nil then
        base = nano[0].tv_sec
    end
    return tonumber(pnano[0].tv_sec - base) + tonumber(pnano[0].tv_nsec)/1000000000.0
end

function clock()
  return ffi.C.clock() / 1000.0
end

local getTimeImpl = nil
function getTime()
  if getTimeImpl == nil then
    local success, _ = pcall(function() return ffi.cast("void*", gl.clock_gettime) end)
    if success then
        getTimeImpl = clock_gettime
    else
        getTimeImpl = clock
    end
  end
  return getTimeImpl()
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



return {
    getTime= getTime,
    base64_encode = base64_encode
}