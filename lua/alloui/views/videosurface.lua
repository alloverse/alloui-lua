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
end

function VideoSurface:awake()
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

return VideoSurface