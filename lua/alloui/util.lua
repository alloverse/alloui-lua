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
]]

function clock_gettime()
    local pnano = assert(ffi.new("nanotime[?]", 1))

    -- CLOCK_REALTIME -> 0
    ffi.C.clock_gettime(0, pnano)
    return pnano[0]
end

local base = nil
function getTime()
    local nano = clock_gettime()
    if base == nil then
        base = nano.tv_sec
    end
    return tonumber(nano.tv_sec - base) + tonumber(nano.tv_nsec)/1000000000.0
end

return {
    getTime= getTime
}