--- Used to display a 3D model asset.
-- @classmod ModelView
local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local View = require(modules.."views.view")
local Bounds = require(modules.."bounds")
local util = require(modules.."util")

class.ModelView(View)

---
--
--~~~ lua
-- model_view = ModelView(bounds, asset)
--~~~
--
-- @tparam [Bounds](Bounds) bounds The bounds of the model that is to be displayed in the world.
-- @tparam [Asset](Asset) asset An asset representing a 3d model.
function ModelView:_init(bounds, asset)
    self:super(bounds or Bounds(0, 0, 0,   1, 1, 1))
    self.asset = asset
    self.color = {1, 1, 1, 1}
    self.nodes = {}

    -- XXX<nevyn> fixme!
    -- this is a hack because removing the `skeleton` comp doesn't seem to be working
    -- after removing the last node. does removeComponent not work in alloplace2?
    self.hasHadNodes = false
end

function ModelView:setAsset(asset)
    self.asset = asset
    self:markAsDirty("geometry")
end

function ModelView:specification()
    local spec = View.specification(self)
    if self.asset then
        table.merge(spec, {
            geometry = {
                type = "asset",
                name = self.asset:id(),
            }
        })
    end
    if self.hasHadNodes or next(self.nodes) then
        spec.skeleton = {
            nodes= self.nodes
        }
    end

    return spec
end

function ModelView:poseNode(nodeName, pose, alpha)
    if alpha == nil then alpha = 1.0 end
    self.hasHadNodes = true
    local m = mat4(pose.transform) -- clone
    m._m = nil -- json-compatible
    self.nodes[nodeName] = {
        matrix= m,
        alpha= alpha
    }
    self:markAsDirty("skeleton")
end

function ModelView:transformNode(nodeName, pose, alpha)
    local default = util.gltf_node_transform(self.asset, nodeName)
    mat4.mul(pose.transform, default, pose.transform)
    self:poseNode(nodeName, pose, alpha)
end

function ModelView:resetNode(nodeName)
    self.nodes[nodeName] = nil
    self:markAsDirty("skeleton")
end

class.BackingPlate(ModelView)
ModelView.BackingPlate = BackingPlate

function BackingPlate:_init(bounds)
    self:super(
        bounds,
        app:_getInternalAsset("models/backing.glb")
    )
    self:layout()
end

function BackingPlate:layout()
    ModelView.layout(self)
    local s = self.bounds.size
    self:transformNode("left",  Pose(0.0, s.width/2, 0.0))
    self:transformNode("right", Pose(0.0, s.width/2, 0.0))
    self:transformNode("top",   Pose(0.0, s.height/2, 0.0))
    self:transformNode("bottom", Pose(0.0, s.height/2, 0.0))
end

return ModelView
