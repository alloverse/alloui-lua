--- A place to emit sound from. Allocates an audio track on backend when created.
-- Use it e g like this to send audio you generate 20ms at a time:
--~~~ lua
--app:scheduleAction(0.02, true, function()
--  local leftAudio, rightAudio = player:generateAudio(960)
--  if left and leftSpeaker.trackId then
--    app.client.client:send_audio(leftSpeaker.trackId, leftAudio)
--  end
--end)
--~~~
-- @classmod Speaker

local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local View = require(modules.."views.view")

class.Speaker(View)
function Speaker:awake()
    self.app.client:sendInteraction({
        sender_entity_id = self.entity.id,
        receiver_entity_id = "place",
        body = {
            "allocate_track",
            "audio",
            48000,
            1,
            "opus"
        }
    }, function(response, body)
        if body[1] == "allocate_track" and body[2] == "ok" then
            self.trackId = body[3]
        else
            print("Speaker failed track allocation: ", pretty.write(body))
        end
    end)
end

return Speaker