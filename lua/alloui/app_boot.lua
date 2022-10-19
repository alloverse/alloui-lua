local projHome = arg[1]
local url = arg[2]
local srcDir = projHome.."/lua"
local alloDir = projHome.."/allo"
local depsDir = projHome.."/allo/deps"
local libDir = projHome.."/allo/lib"

function os.system(cmd, notrim)
    local f = assert(io.popen(cmd, 'r'))
    local s = assert(f:read('*l'))
    f:close()
    if notrim then return s end
    s = string.gsub(s, '^%s+', '')
    s = string.gsub(s, '%s+$', '')
    return s
end

function os.uname()
    return os.system("uname -s")
end

local dylibext = ""
if os.uname():find("^Darwin") ~= nil then
    dylibext = "dylib"
elseif string.match(package.cpath, "so") then
    dylibext = "so"
elseif string.match(package.cpath, "dll") then
    dylibext = "dll"
end

package.path = package.path
    ..";"..srcDir.."/?.lua"
    ..";"..alloDir.."/?.lua"
    ..";"..depsDir.."/alloui/lua/?.lua"
    ..";"..depsDir.."/alloui/lib/cpml/?.lua"
    ..";"..depsDir.."/alloui/lib/pl/lua/?.lua"

local ffi = require 'ffi'

-- load liballonet
allonet = ffi.load(libDir .. "/liballonet."..dylibext, false)

-- load liballonet_av IF AVAILABLE, and initialize it
local libav_available, av = pcall(ffi.load, libDir .. "/liballonet_av."..dylibext, true)
if not libav_available then
    local av_error = av
    av = nil
    print("NOTE: liballonet_av not available, h264 cannot be used: ", av_error)
else
    print("liballonet_av loaded with libavcodec support")
    ffi.cdef [[
    void allo_libav_initialize(void);
    ]]
    ffi.C.allo_libav_initialize()
end
 
Client = require("alloui.client")
ui = require("alloui.ui")
class = require('pl.class')
tablex = require('pl.tablex')
pretty = require('pl.pretty')
vec3 = require("modules.vec3")
mat4 = require("modules.mat4")
local json = require("json")

ui.VideoSurface.libavAvailable = libav_available

ui.App.launchArguments = {}
ui.App.initialLocation = nil
local launchArgss = os.getenv("ALLO_APP_BOOT_ARGS")
local status, launchArgs = pcall(json.decode, launchArgss)
if status then
    ui.App.launchArguments = launchArgs
    if launchArgs.initialLocation then
        ui.App.initialLocation = mat4(launchArgs.initialLocation)
    end
end

-- start app
require("main")
