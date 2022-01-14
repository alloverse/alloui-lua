--- Used to display a 3D model asset.
-- @classmod ModelView
local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local View = require(modules.."views.view")
local Bounds = require(modules.."bounds")

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

    table.merge(spec, {
        material = {
            color = self.color
        }
    })

    if self.texture then 
        table.merge(spec, {
            material = {
                texture = (self.texture.id and self.texture:id()) or self.texture
            }
        })
    end  

    return spec
end

return ModelView
