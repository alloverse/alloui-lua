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
function VideoSurface:_init(bounds, resolution)
    self:super(bounds)
    self.resolution = resolution or {256, 256}
    self.lastFrame = nil
end

--- Set the resolution of the video. This needs to match the width and height sent to sendFrame
function VideoSurface:setResolution(width, height)
    self.resolution = {width, height}
    if self:isAwake() then
        self:takedownVideo()
        self:setupVideo()
    end
end

function VideoSurface:awake()
    View.awake(self)
    self.app:addVideoSurface(self)
    self:setupVideo()
end

function VideoSurface:onComponentAdded(key, component)
    
end

function VideoSurface:setupVideo()
    self.app.client:sendInteraction({
        sender_entity_id = self.entity.id,
        receiver_entity_id = "place",
        body = {
            "allocate_track",
            "video",
            "mjpeg",
            {
                width = self.resolution[1],
                height = self.resolution[2],
            }
        }
    }, function(response, body)
        if body[1] == "allocate_track" and body[2] == "ok" then
            self.trackId = body[3]
        else
            print("VideoSurface failed track allocation: ", pretty.write(body))
        end
    end)
end

function VideoSurface:takedownVideo()
    -- TODO: What to do?
end

--- Send a video frame to the server
-- @tparam pixels string String with pixel data according to format and stride
-- @tparam int width The number of pixels in width. Should match resolution width.
-- @tparam int height The number of pixels in height. Shold match resolution height.
-- @tparam string format The pixel format. For example "bgrx8". Default: "rgba"
-- @tparam int stride The number of bytes for each row of pixels. Default: width*bpp
function VideoSurface:sendFrame(pixels, width, height, format, stride)
    assert(pixels)
    assert(width)
    assert(height)
    self.lastFrame = {
        self.trackId, pixels, width, height, format, stride
    }
    self.app.client.client:send_video(self.trackId, pixels, width, height, format, stride)
end

function VideoSurface:sendLastFrame()
    local track, data, width, height, format, stride = table.unpack(self.lastFrame)
    self:sendFrame(data, width, height, format, stride)
end

return VideoSurface
