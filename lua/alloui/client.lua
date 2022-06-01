--- ???
-- 
-- @classmod Client

local modules = (...):gsub('%.[^%.]+$', '') .. "."
local json = require(modules.."json")
local tablex = require("pl.tablex")
local class = require("pl.class")
local pretty = require("pl.pretty")
local ffi = require("ffi")
local allonet = require(modules.."ffi_allonet_handle")
require(modules.."random_string")

local Client = class.Client()
require(modules.."client_updateState")

local function log(t, message)
    allo_log(t, "client", nil, message)
end

---
--
--~~~ lua
-- client = Client(url, name, client, updateStateAutomatically)
--~~~
--
-- @tparam string url ...
-- @tparam string name ...
-- @tparam [Client](Client) client The AlloNet client.
-- @tparam boolean updateStateAutomatically Whether or not the client should automatically update its state.
function Client:_init(url, name, threaded, updateStateAutomatically)
    self.handle = allonet
    self._client = self.handle.alloclient_create(threaded and true or false)
    self.url = url
    self.placename = "Untitled place"
    self.name = name
    self.outstanding_response_callbacks = {}
    self.outstanding_entity_callbacks = {}
    self.entityCount = 0
    self.state = {
        entities = {}
    }

    self._client.disconnected_callback = function(_client, code, message)
        self.delegates.onDisconnected(code, ffistring(message))
    end
    self._client.interaction_callback = function(_client, c_inter)
        -- TODO: convert c_inter to a lua table or add metatable to c_inter
        self:onInteraction({
            type = ffi.string(c_inter.type),
            sender_entity_id = ffi.string(c_inter.sender_entity_id),
            receiver_entity_id = ffi.string(c_inter.receiver_entity_id),
            request_id = ffi.string(c_inter.request_id),
            body = ffi.string(c_inter.body),
        })
        return true
    end
    if updateStateAutomatically == nil or updateStateAutomatically == true then
        self._client.state_callback = function(_client, state, diff)
            self:updateState(state, diff)
        end
    end
    self._client.audio_callback = function(_client, track_id, pcm, sample_count)
        local track_id = tonumber(track_id)
        local data = ffi.string(pcm, sample_count*2)
        return self.delegates.onAudio(track_id, data)
    end
    self._client.video_callback = function(_client, track_id, pixels, wide, high)
        local track_id = tonumber(track_id)
        local wide = tonumber(wide)
        local high = tonumber(high)
        local pixels = ffi.string(pixels, wide*high*4)
        return self.delegates.onVideo(track_id, wide, high, pixels)
    end
    self._client.asset_request_bytes_callback = function(client, asset_id, offset, length)
        local asset_id = ffistring(asset_id)
        local offset = tonumber(offset) + 1
        local length = tonumber(length)
        self.delegates.onAssetRequestBytes(asset_id, offset, length)
    end
    self._client.asset_receive_callback = function(client, asset_id, buffer, offset, length, total_size)
        local asset_id = ffistring(asset_id)
        local buffer = ffi.string(buffer, length)
        local offset = tonumber(offset) + 1
        local total_size = tonumber(total_size)
        self.delegates.onAssetReceive(asset_id, buffer, offset+1, total_size)
    end
    self._client.asset_state_callback = function(client, asset_id, state)
        local asset_id = ffistring(asset_id)
        self.delegates.onAssetState(asset_id, tonumber(state))
    end

    self.avatar_id = ""

    self.delegates = {
        onStateChanged = function() end,
        onEntityAdded = function(e) end,
        onEntityRemoved = function(e) end,
        onComponentAdded = function(k, v) end,
        onComponentChanged = function(k, v) end,
        onComponentRemoved = function(k, v) end,
        onInteraction = function(inter, body, receiver, sender) end,
        onConnected = function () end,
        onDisconnected = function(code, message) end,
        onAudio = function(track_id, audio) end,
        onVideo = function(track_id, pixels, wide, high) end,
        onAssetRequestBytes = function(asset_id, offset, length) end,
        onAssetReceive = function(asset_id, buffer, offset, total_size) end,
        onAssetState = function(asset_id, state) end,
    }
    self.connected = false

    return self
end

function Client:connect(avatar_spec)
    return self.handle.alloclient_connect(self._client,
        self.url,
        json.encode({display_name = self.name}),
        json.encode(avatar_spec)
    )
end

function Client:getEntity(eid, cb)
    local existing = self.state.entities[eid]
    if existing then
        cb(existing)
    else
        local equeries = self.outstanding_entity_callbacks[eid] or {}
        table.insert(equeries, cb)
        self.outstanding_entity_callbacks[eid] = equeries
    end
end

function Client:_respondToEquery(e)
    local equeries = self.outstanding_entity_callbacks[e.id]
    if equeries then
        for i, cb in ipairs(equeries) do
            cb(e)
        end
        self.outstanding_entity_callbacks[e.id] = nil
    end
end

function Client:spawnEntity(spec, cb)
  assert(self.avatar_id ~= nil)
  self:sendInteraction({
    sender_entity_id = self.avatar_id,
    receiver_entity_id = "place",
    body = {
        "spawn_entity",
        spec
    }
  }, function(response, body)
    if cb == nil then return end
    if #body == 2 then
      local eid = body[2]
      self:getEntity(eid, cb)
    else
      cb(false)
    end
  end)
end

--- Send an RPC message (aka "interaction") to another entity.
-- If you're sending a "request" interaction (default), you should really
-- listen to the callback to make sure your call succeeded.
-- @tparam interaction Interaction a populated Interaction struct
-- @tparam callback Function(interaction, body) a callback that takes the response interaction and the parsed response body.
function Client:sendInteraction(interaction, callback)
    if interaction.sender then
      interaction.sender_entity_id = interaction.sender.id
      interaction.sender = nil
    end
    if interaction.receiver then
      interaction.receiver_entity_id = interaction.receiver.id
      interaction.receiver = nil
    end

    if interaction.sender_entity_id == nil then
        assert(self.avatar_id ~= nil)
        interaction.sender_entity_id = self.avatar_id
    end
    if interaction.type == nil then
        interaction.type = "request"
    end
    if interaction.type == "request" then
        interaction.request_id = string.random(16)
        if callback ~= nil then
            self.outstanding_response_callbacks[interaction.request_id] = callback
        end
    elseif interaction.request_id == nil then
        interaction.request_id = "" -- todo, fix this in allonet
    end
    interaction.body = json.encode(interaction.body)

    local cinter = self.handle.allo_interaction_create(
        interaction.type,
        interaction.sender_entity_id,
        interaction.receiver_entity_id,
        interaction.request_id,
        interaction.body
    )
    self.handle.alloclient_send_interaction(self._client, cinter)
    self.handle.allo_interaction_free(cinter)
    return interaction.request_id
end

function Client:onInteraction(inter)
    local body = json.decode(inter.body)
    if body[1] == "announce" then
        if body[2] == "error" then
          local code = body[3]
          local errstr = body[3]
          log("ERROR", "Place did not accept our announce:", code, errstr)
          -- allonet will now disconnect us
          return
        end
        self.avatar_id = body[2]
        self.placename = body[3]
        log("INFO", string.format("Welcome to %s, %s. Our avatar ID is %s", self.placename, self.name, self.avatar_id))
        self.connected = true
        self.delegates.onConnected()
    end

    if inter.type == "request" then
      inter.respond = function(request, responseBody)
        local response = {
          sender_entity_id = inter.receiver_entity_id,
          receiver_entity_id = inter.sender_entity_id,
          request_id = inter.request_id,
          type = "response",
          body = responseBody
        }
        self:sendInteraction(response)
      end
    end

    local callback = self.outstanding_response_callbacks[inter.request_id]
    if callback ~= nil then
        callback(inter, body)
        self.outstanding_response_callbacks[inter.request_id] = nil
    else
        local sender = self.state.entities[inter.sender_entity_id]
        local receiver = self.state.entities[inter.receiver_entity_id]
        self.delegates.onInteraction(inter, body, receiver, sender)
    end
end

function Client:setIntent(intent)
    self.handle.alloclient_set_intent(self._client, intent)
end

function Client:sendAudio(trackId, audio)
    self.handle.alloclient_send_audio_data(self._client, trackId, audio, #audio)
end

local formatTable = {
    rgba = allonet.allopicture_format_rgba8888,
    bgra = allonet.allopicture_format_bgra8888,
    bgrx8 = allonet.allopicture_format_bgra8888,
    xrgb8 = allonet.allopicture_format_xrgb8888,
    rgb1555 = allonet.allopicture_format_rgb1555,
    rgb565 = allonet.allopicture_format_rgb565,
}

function Client:sendVideo(trackId, pixels, width, height, format, stride)
    local cformat = formatTable[format]
    assert(cformat, "Invalid format: " .. tostring(format))
    self.handle.alloclient_send_video_pixels(self._client, trackId, pixels, width, height, cformat, stride);
end

--- Send and receive buffered data synchronously now. Loops over all queued
-- network messages until the queue is empty.
-- @param timeout_ms how many ms to wait for incoming messages before giving up. Default 10.
-- @discussion Call regularly at 20hz to process incoming and outgoing network traffic.
-- @return bool whether any messages were parsed
function Client:poll(timeout)
    return self.handle.alloclient_poll(self._client, timeout)
end

-- Can not call jit functions that in turn callback into lua functions
-- This for some reason does work in the visor tho!
local function DisablePollFFI()
    local status, _ = pcall(require, "lovr")
    if not status then
        jit.off(Client.poll)
    end
end
DisablePollFFI()

function Client:simulate()
    self.handle.alloclient_simulate(self._client)
end

function Client:disconnect(code)
    self.handle.alloclient_disconnect(self._client, code)
end

function Client:run()
    while true do
        self:poll(1.0/20.0)
    end
end

function Client:getClientTime()
    return self.handle.get_ts_monod()
end

function Client:getServerTime()
    return self.handle.alloclient_get_time(self._client)
end

function Client:getStats()
    local buffersize = 1024
    local buffer = ffi.new("char[?]", buffersize)
    self.handle.alloclient_get_stats(self._client, buffer, buffersize)
    return ffi.string(buffer, buffersize)
end

function Client:getLatency()
    return self._client.clock_latency
end

function Client:getClockDelta()
    return self._client.clock_deltaToServer
end

function Client:createIntent(t, use_gc)
    use_gc = use_gc or true
    local cintent = self.handle.allo_client_intent_create()
    if use_gc then 
        cintent = ffi.gc(cintent, self.handle.allo_client_intent_free)
    end
    
    assert(cintent and t.entity_id)
    cintent.entity_id = ffi.C.malloc(#t.entity_id + 1) -- free'd with the intent
    ffi.copy(cintent.entity_id, t.entity_id)
    cintent.wants_stick_movement = t.wants_stick_movement or false
    cintent.xmovement = t.xmovement or 0
    cintent.zmovement = t.zmovement or 0
    cintent.yaw = t.yaw or 0
    cintent.pitch = t.pitch or 0
    if t.poses then cintent.poses = t.poses end

    return cintent
end

function Client:simulateRootPose(avatar_id, dt, cintent)
    assert(avatar_id, cintent)

    self.handle.allosim_simulate_root_pose(
        self.handle.alloclient_get_state(self._client),
        avatar_id,
        dt,
        cintent
    )
end

-- Assets

function Client:requestAsset(assetId)
    self.handle.alloclient_asset_request(self._client, assetId, nil);
end

function Client:sendAsset(assetId, data, offset, total_size)
    if data == nil then self:sendAssetNotAvailable(assetId) end
    self.handle.alloclient_asset_send(self._client, assetId, data, offset-1, #data, total_size)
end

function Client:sendAssetNotAvailable(assetId)
    self.handle.alloclient_asset_send(self._client, assetId, nil, 0, 0, 0)
end


return Client
