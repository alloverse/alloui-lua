--- An entity is the manifestation of an agent in a place.
-- The only fixed information in an entity is its id. Everything else is specified as a set of components.
-- @classmod Entity
local class = require('pl.class')
local mat4 = require("modules.mat4")

function newMat(x)
    if lovr then
        return lovr.math.newMat4(x.mul and x or unpack(x))
    else
        return mat4.new(x)
    end
end

function newTempMat(x)
    if lovr then
        return lovr.math.mat4(x)
    else
        return mat4.new(x)
    end
end

function matMul(x, y)
    if lovr then
        return x:mul(y)
    else
        return mat4.mul(x, x, y)
    end
end

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

function Component:_wasCreated()

end
function Component:_wasUpdated(oldValue)

end

class.TransformComponent(Component)
function TransformComponent:transformFromParent()
    self:_recalculateTransforms()
    assert(self._cachedTransformFromParent)
    return newTempMat(self._cachedTransformFromParent)
end

function TransformComponent:transformFromWorld()
    self:_recalculateTransforms()
    assert(self._cachedTransformFromWorld)
    return newTempMat(self._cachedTransformFromWorld)
end

function TransformComponent:_recalculateTransforms()
    self._cachedTransformFromParent = newMat(self.matrix)
    self._cachedTransformFromWorld = nil

    local parent = self:getEntity():getParent()
    if not parent then
        self._cachedTransformFromWorld = newMat(self.matrix)
    else
        local parentWorldTransform = parent.components.transform._cachedTransformFromWorld
        if parentWorldTransform then
            self._cachedTransformFromWorld = matMul(newMat(parentWorldTransform), self._cachedTransformFromParent)
        else
            -- punt until parent calls us again and asks us to recalc.
            return
        end
    end
    
    for _, child in ipairs(self:getEntity():getChildren()) do
        child.components.transform:_recalculateTransforms()
    end
end

function TransformComponent:_wasCreated()
    self:_recalculateTransforms()
end

function TransformComponent:_wasUpdated(oldValue)
    self:_recalculateTransforms()
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

function RelationshipsComponent:_wasCreated()
    self:getEntity().components.transform:_recalculateTransforms()
end

function RelationshipsComponent:_wasUpdated(oldValue)
    self:getEntity().components.transform:_recalculateTransforms()
end

local components = {
    transform = TransformComponent,
    relationships = RelationshipsComponent
}
-- default to plain Component
setmetatable(components, {__index = function () return Component end})

-- multiple return values doesn't work?? :/
return {Entity, components}
