--- A place to emit sound from. It can either play live-streamed audio or
-- static sound files:
-- * If given a sound effect asset to its constructor, it will play that
--   asset looping
-- * If not given a sound effect, it will allocate a live_media track,
--   which you can then use to send_audio with:
--~~~ lua
--local leftSpeaker = ui.Speaker(ui.Bounds(0,0,0,  1,1,1))
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

function Speaker:_init(bounds, effect)
    self:super(bounds)
    if effect then
        self.effect = effect
        self.loopCount = 99999999999999
        self.volume = 0.5
        self.startsAt = 0 -- todo, set to now somehow
    end
end

function Speaker:awake()
    -- only play sound effect one is provided
    if self.effect then return end

    -- otherwise allocate a track for live streaming
    self.app.client:sendInteraction({
        sender_entity_id = self.entity.id,
        receiver_entity_id = "place",
        body = {
            "allocate_track", "audio", "opus",
            {
                sample_rate= 48000,
                channel_count= 1,
                channel_layout= "mono"
            }
        }
    }, function(response, body)
        if body[1] == "allocate_track" and body[2] == "ok" then
            self.trackId = body[3]
        else
            print("Speaker failed track allocation: ", pretty.write(body))
        end
    end)
end

function Speaker:specification()
    if not self.effect then return View.specification(self) end
    print("Starts at", self.startsAt)
    return tablex.union(View.specification(self), {
        sound_effect= {
            asset= self.effect:id(),
            loop_count= self.loopCount,
            volume= self.volume,
            starts_at= self.startsAt
        }
    })
end

return Speaker
