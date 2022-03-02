--- An entity is the manifestation of an agent in a place.
-- The only fixed information in an entity is its id. Everything else is specified as a set of components.
-- @classmod Entity
local class = require('pl.class')
local mat4 = require("modules.mat4")

class.Entity()
--- Gets the parent of a given Entity.  
-- @treturn [Entity](Entity) The parent Entity, or nil if it has no parent.
function Entity:getParent()
    local relationships = self.components.relationships
    if relationships ~= nil then
        return relationships:getParent()
    end
    return nil
end

--- Gets the topmost parent of a given Entity. E g, if given a user's hand,
-- gets the root avatar for that user.
function Entity:getAncestor()
    local current = self
    while current:getParent() ~= nil do
        current = current:getParent()
    end
    return current
end

--- Finds the first descendant of self where calling predicate with each
-- descendant returns true.
-- @tparam Callback(entity):Bool The predicate callback to run for each descendant
-- @treturn Entity|nil the found entity, or nil if non found
function Entity:getMatchingDescendant(predicate)
    for _, child in ipairs(self:getChildren()) do
        if predicate(child) then
            return child
        end
        local match = child:getMatchingDescendant(predicate)
        if match then
            return match
        end
    end
    return nil
end

-- Implemented as a field override in Client:updateState
function Entity:getChildren()
    return self.children
end

-- Implemented as a field override in Client:updateState
function Entity:getSibling(eid)
  return nil
end

class.Component()
-- Implemented as a field override in NetworkScene:onStateChanged
function Component:getEntity()
  return nil
end

class.TransformComponent(Component)
function TransformComponent:transformFromParent()
    if lovr then
        return lovr.math.mat4(unpack(self.matrix))
    else
        return mat4.new(self.matrix)
    end
end

function TransformComponent:transformFromWorld()
    local parent = self:getEntity():getParent()
    local myMatrix = self:transformFromParent()
    if parent ~= nil then
        local parentMatrix = parent.components.transform:transformFromWorld()
        if lovr then
            return parentMatrix:mul(myMatrix)
        else
            return mat4.mul(myMatrix, parentMatrix, myMatrix)
        end
    else
        return myMatrix
    end
end

function TransformComponent:getMatrix()
    return self:transformFromWorld()
end

class.RelationshipsComponent(Component)
function RelationshipsComponent:getParent()
    if self.parent == nil or self.parent == "" then
        return nil
    end
    return self:getEntity():getSibling(self.parent)
end

local components = {
    transform = TransformComponent,
    relationships = RelationshipsComponent
}
-- default to plain Component
setmetatable(components, {__index = function () return Component end})

-- multiple return values doesn't work?? :/
return {Entity, components}
