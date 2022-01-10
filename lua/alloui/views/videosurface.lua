--- A surface that allocates a video media track to use as texture
-- Send frames like this
--~~~ lua
--app:scheduleAction(0.02, true, function()
--  if surface and surface.trackId then
--    app.client.client:send_video(surface.trackId, pixeldata, width, height, [format=rgba8], [stride=width])
--  end
--end)
--~~~
-- @classmod VideoSurface

local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local Surface = require(modules.."views.surface")

local VideoSurface = class.VideoSurface(Surface)

--- Initiate a video surface. 
-- A video track will be allocated for the surface. The resolution can not be changed later. 
-- @tparam [Bounds](bounds) bounds The position and size of the surface
-- @tparam resolution|{int, int} A table with width and height giving the pixel resolution of the video. Must match the width and height sent to `sendFrame`
function VideoSurface:_init(bounds, resolution)
    self:super(bounds)
    self.resolution = resolution or {256, 256}
    self.lastFrame = nil
    self.encoderFormat = "mjpeg" -- TODO: detect availability and default to h264 with fallback to mjpeg
    self.isReady = false -- ready to send frames?
end

--- Set the input video resolution. Must be called before awakened.
function VideoSurface:setResolution(width, height)
    if self:isAwake() then
        error("You can't change the resolution of an allocated video track")
    end
    self.resolution = {width, height}
end

--- Set the output video encoder format. Default "mjpeg" which is slow but compatible.
--  You can also set it to "h264" if you provide liballonet-av, libavcodec etc.
function VideoSurface:setVideoFormat(fmt)
    if self:isAwake() then
        error("You can't change the format of an allocated video track")
    end
    self.encoderFormat = fmt
end

function VideoSurface:awake()
    View.awake(self)
    self.app:addVideoSurface(self)
    self:setupVideo()
end

function VideoSurface:sleep()
    self.isReady = false
    View.sleep(self)
    self.app:removeVideoSurface(self)
end

function VideoSurface:onComponentAdded(key, component)
    
end

function VideoSurface:setupVideo()
    print("Allocating video track with width ".. self.resolution[1] .. " height " .. self.resolution[2])
    self.app.client:sendInteraction({
        sender_entity_id = self.entity.id,
        receiver_entity_id = "place",
        body = {
            "allocate_track",
            "video",
            self.encoderFormat,
            {
                width = self.resolution[1],
                height = self.resolution[2],
            }
        }
    }, function(response, body)
        if body[1] == "allocate_track" and body[2] == "ok" then
            self.trackId = body[3]
            self.isReady = true
        else
            print("VideoSurface failed track allocation: ", pretty.write(body))
        end
    end)
end

--- Send a video frame to the server
-- @tparam pixels string String with pixel data according to format and stride
-- @tparam int width The number of pixels in width. Should match the width set at init.
-- @tparam int height The number of pixels in height. Shold match the height set at init.
-- @tparam string format The pixel format. For example "bgrx8". Default: "rgba"
-- @tparam int stride The number of bytes for each row of pixels. Default: width*bpp
function VideoSurface:sendFrame(pixels, width, height, format, stride)
    if not self.isReady then return end
    assert(pixels)
    assert(width)
    assert(height)
    self.lastFrame = {
        self.trackId, pixels, width, height, format, stride
    }
    self.app.client.client:send_video(self.trackId, pixels, width, height, format, stride)
end

function VideoSurface:sendLastFrame()
    if not self.isReady then return end
    if not self.lastFrame then return end
    local track, data, width, height, format, stride = table.unpack(self.lastFrame)
    self:sendFrame(data, width, height, format, stride)
end

return VideoSurface
