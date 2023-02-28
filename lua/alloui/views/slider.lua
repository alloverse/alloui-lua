--- A slider component for selecting a value from a range
--
-- @classmod Slider

local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."
local class = require('pl.class')
local vec3 = require("modules.vec3")
local View = require(modules.."views.view")
local Bounds = require(modules.."bounds")
local Cube = require(modules.."views.cube")

local Slider = class.Slider(View)


function Slider:_init(bounds)
    self.trackModel = app:_getInternalAsset("models/slider-track.glb")
    self.knobModel =  app:_getInternalAsset("models/slider-knob.glb")

    self.track = ModelView(Bounds.unit(), self.trackModel)
    self.knob =  ModelView(Bounds.unit(), self.knobModel)

    bounds = bounds or Bounds(0,0,0, 0.8, 0.13, 0.1)
    self:super(bounds)
    self._minValue = 0.0
    self._maxValue = 1.0
    self._currentValue = 0.5



    self:addSubview(self.track)
    self:addSubview(self.knob)

    self:setPointable(true)
    self:layout()
end


function Slider:layout()
    local fraction = (self._currentValue - self._minValue) / (self._maxValue - self._minValue)
    local x = fraction * self.bounds.size.width - self.bounds.size.width / 2
    local bounds = self.bounds
    self.track.bounds = bounds:copy():moveToOrigin():scale(bounds.size.height, bounds.size.height, bounds.size.height)
    self.knob.bounds  = bounds:copy():moveToOrigin():scale(bounds.size.height, bounds.size.height, bounds.size.height)
    self.knob.bounds:move(x, 0, 0)

    self.track:setBounds()
    self.knob:setBounds()

    local scaledWidth = bounds.size.width / bounds.size.height
    self.track:transformNode("Left", Pose(0.0, scaledWidth/2, 0.0))
    self.track:transformNode("Right", Pose(0, scaledWidth/2, 0))
end

function Slider:activate(sender, value)

end

function Slider:onTouchDown(pointer)
    local point = self:convertPointFromView(pointer.pointedTo or vec3.new(), nil)
    local fraction = (point.x + self.bounds.size.width / 2) / self.bounds.size.width

    if fraction < 0 or fraction > 1 then return end

    local newValue = self._minValue + (fraction * (self._maxValue - self._minValue))
    self:currentValue(newValue)
    self:valueChanged(pointer.hand)
    self:activate(pointer.hand, newValue)
end

function Slider:onPointerMoved(pointer)
    if pointer.state == "touching" then
        self:onTouchDown(pointer)
    end
end

--- Get or set the minimum selectable value
function Slider:minValue(newValue)
    if newValue then 
        self._minValue = newValue
        self:layout()
    end
    return self._minValue
end

--- Get or set the maximum selecrtable value
function Slider:maxValue(newvalue)
    if newvalue then
        self._maxValue = newvalue
        self:layout()
    end
    return self._maxValue
end

--- Get or set the current value
function Slider:currentValue(newValue)
    if newValue then 
        self._currentValue = newValue
        self:layout()
    end
    return self._currentValue
end

function Slider:valueChanged(sender)
    if self.onValueChanged then 
        self.onValueChanged(sender, self._currentValue)
    end
end

return Slider
