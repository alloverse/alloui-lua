--- ???
-- 
-- @classmod Client

local modules = (...):gsub('%.[^%.]+$', '') .. "."
local json = require(modules.."json")
local tablex = require("pl.tablex")
local Entity, componentClasses = unpack(require(modules.."entity"))
local class = require("pl.class")
local pretty = require("pl.pretty")
require(modules.."random_string")

class.Client()

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
function Client:_init(url, name, client, updateStateAutomatically)
    self.client = client and client or allonet.create()
    self.url = url
    self.placename = "Untitled place"
    self.name = name
    self.outstanding_response_callbacks = {}
    self.outstanding_entity_callbacks = {}
    self.state = {
        entities = {}
    }

    self.client:set_disconnected_callback(function(code, message)
        self.delegates.onDisconnected(code, message)
    end)
    self.client:set_interaction_callback(function(inter)
        self:onInteraction(inter)
    end)
    if updateStateAutomatically == nil or updateStateAutomatically == true then
        self.client:set_state_callback(function(state)
            self:updateState(state)
        end)
    end
    self.client:set_audio_callback(function(track_id, audio)
        self.delegates.onAudio(track_id, audio)
    end)
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

function Client:updateState(newState)
    if newState == nil then
        newState = self.client:get_state()
    end

    local oldEntities = tablex.copy(self.state.entities)

    -- Compare existing state to the new incoming state, and apply appropriate functions when we're done.
    local newEntities = {}
    local deletedEntities = {}
    local newComponents = {}
    local updatedComponents = {}
    local deletedComponents = {}
    self.entityCount = 0

    -- While at it, also make Entities and their Components classes so they get convenience methods from entity.lua
  
    -- Entity:getSibling(eid) to get any entity from an entity.
    local getSibling = function(this, id) return self.state.entities[id] end
  
    for eid, newEntity in pairs(newState.entities) do
      local existingEntity = oldEntities[eid]
      local entity = existingEntity
      self.entityCount = self.entityCount + 1
      
      -- Check for new entity
      if entity == nil then
        entity = newEntity
        setmetatable(entity, Entity)
        entity.getSibling = getSibling
        table.insert(newEntities, entity)
        self.state.entities[eid] = newEntity
      end
      
      -- Component:getEntity()
      local getEntity = function() return entity end
  
      -- Check for new or updated components
      for cname, newComponent in pairs(newEntity.components) do
        local oldComponent = existingEntity and existingEntity.components[cname]
        if oldComponent == nil then
          -- it's a new component
          local klass = componentClasses[cname]
          setmetatable(newComponent, klass)
          newComponent.getEntity = getEntity
          newComponent.key = cname
          entity.components[cname] = newComponent
          table.insert(newComponents, newComponent)
        else
          -- copy these over so old and new aren't considered different just 'cause getEntity is another closure
          newComponent.key = oldComponent.key
          newComponent.getEntity = oldComponent.getEntity
          if tablex.deepcompare(oldComponent, newComponent, false) == false then
            -- it's a changed component
            local oldCopy = tablex.deepcopy(oldComponent)
            table.insert(updatedComponents, {
              old=oldCopy,
              new=oldComponent -- will be new after copy
            })
            -- copy over new values...
            for key, value in pairs(newComponent) do
              oldComponent[key] = value
            end
            -- and remove now-removed values...
            for key, _ in pairs(oldComponent) do
              if newComponent[key] == nil then
                oldComponent[key] = nil
              end
            end
          end
        end
      end
      -- Check for deleted components
      if existingEntity ~= nil then
        for cname, oldComponent in pairs(existingEntity.components) do
          local newComponent = newEntity.components[cname]
          if newComponent == nil then
            table.insert(deletedComponents, oldComponent)
            entity.components[cname] = nil
          end
        end
      end
    end
  
    -- check for deleted entities
    for eid, oldEntity in pairs(oldEntities) do
      local newEntity = newState.entities[eid]
      if newEntity == nil then      
        table.insert(deletedEntities, oldEntity)
        tablex.insertvalues(deletedComponents, tablex.values(oldEntity.components))
        self.state.entities[eid] = nil
      end
    end
  
    -- Run callbacks
    if self.connected == false then
      self.connected = true
      self.delegates.onConnected()
    end

    self.delegates.onStateChanged()
    tablex.map(function(x) 
        self.delegates.onEntityAdded(x) 
    end, newEntities)
    tablex.map(function(x) self.delegates.onEntityRemoved(x) end, deletedEntities)
    tablex.map(function(x) self.delegates.onComponentAdded(x.key, x) end, newComponents)
    tablex.map(function(x) self.delegates.onComponentChanged(x.new.key, x.new, x.old) end, updatedComponents)
    tablex.map(function(x) self.delegates.onComponentRemoved(x.key, x) end, deletedComponents)
    tablex.map(function(x) 
      self:_respondToEquery(x)
  end, newEntities)
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
        self.avatar_id = body[2]
        self.placename = body[3]
        print("Welcome to",self.placename,", ",self.name,". Our avatar ID: " .. self.avatar_id)
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
