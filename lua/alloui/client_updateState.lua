local modules = (...):gsub('%.[^%.]+$', '') .. "."
local Entity, componentClasses = unpack(require(modules.."entity"))
local tablex = require("pl.tablex")
local pretty = require("pl.pretty")

function Client:updateState(newState, diff)
  local oldEntities = tablex.copy(self.state.entities)

  -- Compare existing state to the new incoming state, and apply appropriate functions when we're done.
  local newEntities = {}
  local deletedEntities = {}
  local newComponents = {}
  local updatedComponents = {}
  local deletedComponents = {}

  -- Entity:getSibling(eid) to get any entity from an entity.
  local getSibling = function(this, id) return self.state.entities[id] end

  ---------------
  -- NEW ENTITIES
  ---------------
  for i, eid in ipairs(diff.newEntities) do
    local newEntity = {
      id= eid,
      components= {},
      raw_components= {},
    }
    self.entityCount = self.entityCount + 1
    
    setmetatable(newEntity, Entity)
    newEntity.getSibling = getSibling
    newEntity.children = {}
    table.insert(newEntities, entity)
    self.state.entities[eid] = newEntity
  end

  ---------------
  -- DELETED ENTITIES
  ---------------
  for i, eid in ipairs(diff.deletedEntities) do
    local oldEntity = oldEntities[eid]
    table.insert(deletedEntities, oldEntity)
    self.state.entities[eid] = nil
    self.entityCount = self.entityCount - 1
  end

  ---------------
  -- NEW COMPONENTS
  ---------------
  
  for i, cspec in ipairs(diff.newComponents) do
    local eid, cname, _, cdata  = unpack(cspec)
    local entity = self.state.entities[eid]
    -- store raw component before adding metatable etc, so we can know exactly what we had before
    entity.raw_components[cname] = tablex.deepcopy(cdata)
    
    cdata.getEntity = function() return entity end
    local klass = componentClasses[cname]
    setmetatable(cdata, klass)
    cdata.key = cname

    entity.components[cname] = cdata
    table.insert(newComponents, cdata)
  end
    
  ---------------
  -- UPDATED COMPONENTS
  ---------------
  for i, cspec in ipairs(diff.updatedComponents) do
    local eid, cname, _, cdata = unpack(cspec)
    local entity = self.state.entities[eid]
    local comp = entity.components[cname]
    local oldComponent = tablex.deepcopy(comp)
    local oldRawComponent = entity.raw_components[cname]

    entity.raw_components[cname] = tablex.deepcopy(cdata)

    -- remove things no longer present in component
    for k, _ in pairs(oldRawComponent) do
      if cdata[k] == nil then
        comp[k] = nil
      end
    end
    
    -- add new or updated fields in component
    for k, v in pairs(cdata) do
      comp[k] = v
    end
    table.insert(updatedComponents, {
      old= oldComponent,
      new= comp
    })
  end

  ---------------
  -- DELETED COMPONENTS
  ---------------
  for i, cspec in ipairs(diff.deletedComponents) do
    local eid, cname, cdata, _ = unpack(cspec)
    local entity = oldEntities[eid]
    local comp = entity.components[cname]
    local oldComponent = entity.components[cname]
    entity.components[cname] = nil
    entity.raw_components[cname] = nil
    table.insert(deletedComponents, oldComponent)
  end

  ---------------
  -- UPDATE CHILDREN AND PARENT POINTERS
  ---------------
  self:updateRelationships(newComponents, updatedComponents, deletedComponents)

  ---------------
  -- RUN CALLBACKS
  ---------------
  --print("STATE CHANGED!", pretty.write({newEntities= newEntities, deletedEntities= deletedEntities, newComponents= newComponents, updatedComponents= updatedComponents, deletedComponents= deletedComponents}))

  self.delegates.onStateChanged()
  tablex.map(function(x) self.delegates.onEntityAdded(x) end, newEntities)
  tablex.map(function(x) self.delegates.onEntityRemoved(x) end, deletedEntities)
  tablex.map(function(x) self.delegates.onComponentAdded(x.key, x) end, newComponents)
  tablex.map(function(x) self.delegates.onComponentChanged(x.new.key, x.new, x.old) end, updatedComponents)
  tablex.map(function(x) self.delegates.onComponentRemoved(x.key, x) end, deletedComponents)
  tablex.map(function(x) self:_respondToEquery(x) end, newEntities)
end

function Client:updateRelationships(newComponents, updatedComponents, deletedComponents)
    for _, comp in ipairs(newComponents) do
      if comp.key == "relationships" and comp.parent then
        -- it's a programmer error for an entity to have a relationship to a non-existing
        -- entity, but it might still happen...
        local parentEnt = self.state.entities[comp.parent]
        if parentEnt then
          table.insert(parentEnt.children, comp:getEntity())
        end
      end
    end
    for _, change in ipairs(updatedComponents) do
      if change.new.key == "relationships" then
        if change.old.parent then
          local idx = tablex.find(self.state.entities[change.old.parent].children, change.old:getEntity())
          table.remove(self.state.entities[change.old.parent].children, idx)
        end
        if change.new.parent then
          table.insert(self.state.entities[change.new.parent].children, change.new:getEntity())
        end
      end
    end
    for _, comp in ipairs(deletedComponents) do
      if comp.key == "relationships" and comp.parent then
        local parent = self.state.entities[comp.parent]
        if parent then
          local idx = tablex.find(parent.children, comp:getEntity())
          table.remove(parent.children, idx)
        end
      end
    end
end