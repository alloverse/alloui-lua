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
    bounds = bounds or Bounds(0,0,0, 0.8, 0.13, 0.1)
    self:super(bounds)
    self._minValue = 0.0
    self._maxValue = 1.0
    self._currentValue = 0.5

    self.color = {1, 0, 0, 1}

    self.track = Cube()
    self.knob = Cube()

    self:addSubview(self.track)
    self:addSubview(self.knob)

    self.knob.color = {0.5, 0, 0.4, 1}
    self:setPointable(true)
    self:layout()
end


function Slider:layout()
    self.track.bounds.size = self.bounds.size:copy()
    self.track.bounds.size.height = self.bounds.size.height / 2.0
    self.track.bounds.size.depth = self.bounds.size.depth / 2.0

    self.knob.bounds.size = self.bounds.size:copy()
    self.knob.bounds.size.width = self.knob.bounds.size.height/2

    local fraction = (self._currentValue - self._minValue) / (self._maxValue - self._minValue)
    local x = fraction * self.bounds.size.width - self.bounds.size.width / 2
    self.knob.bounds:moveToOrigin():move(x, 0, 0)

    self.track:markAsDirty("transform")
    self.knob:markAsDirty("transform")
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