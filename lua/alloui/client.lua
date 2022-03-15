--- ???
-- 
-- @classmod Client

local modules = (...):gsub('%.[^%.]+$', '') .. "."
local json = require(modules.."json")
local tablex = require("pl.tablex")
local class = require("pl.class")
local pretty = require("pl.pretty")
local ffi = require("ffi")
require(modules.."random_string")

class.Client()
require(modules.."client_updateState")
require(modules.."client_native")

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
    self.handle = self:createNativeHandle()
    self.client = self.handle.alloclient_create(threaded)

    self.url = url
    self.placename = "Untitled place"
    self.name = name
    self.outstanding_response_callbacks = {}
    self.outstanding_entity_callbacks = {}
    self.entityCount = 0
    self.state = {
        entities = {}
    }

    self.client.disconnected_callback = function(_client, code, message)
        self.delegates.onDisconnected(code, message)
    end
    self.client.interaction_callback(function(_client, c_inter)
        -- TODO: convert c_inter to a lua table
        self:onInteraction(inter)
    end)
    if updateStateAutomatically == nil or updateStateAutomatically == true then
        self.client.state_callback = function(_client, state, diff)
            self:updateState(state, diff)
        end
    end
    self.client.audio_callback = function(_client, track_id, pcm, sample_count)
        self.delegates.onAudio(track_id, ffi.string(pcm, sample_count*2))
    end
    self.client.video_callback = function(_client, track_id, pixels, wide, high)
        self.delegates.onVideo(track_id, wide, high, pixels)
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
    }
    self.connected = false

    return self
end

function Client:connect(avatar_spec)
    return self.client:connect(
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
    self.client:send_interaction(interaction)
    return interaction.request_id
end

function Client:onInteraction(inter)
    local body = json.decode(inter.body)
    if body[1] == "announce" then
        if body[2] == "error" then
          local code = body[3]
          local errstr = body[3]
          print("Place did not accept our announce:", code, errstr)
          -- allonet will now disconnect us
          return
        end
        self.avatar_id = body[2]
        self.placename = body[3]
        print("Welcome to",self.placename,", ",self.name,". Our avatar ID: " .. self.avatar_id)
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
  self.client:set_intent(intent)
end

function Client:sendAudio(trackId, audio)
  self.client:send_audio(trackId, audio)
end

function Client:poll(timeout)
  self.client:poll(timeout)
end

function Client:simulate()
  self.client:simulate()
end

function Client:disconnect(code)
  self.client:disconnect(code)
end

function Client:run()
    while true do
        self.client:poll(1.0/20.0)
    end
end

return Client
