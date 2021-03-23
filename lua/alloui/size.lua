--- The size (in meters) of a view or element in the world.  
-- Note that size and scale are different things: size is the semantic size of your app
-- (e g "this button is 2 dm wide") while scale is the scaling up or down of this semantic
-- size (e g a transformation matrix with a 2.0 X-axis scale and a 2dm width is 4dm wide, but its
-- content is still 2dm wide.)
-- @classmod Size

local modules = (...):gsub(".[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')


class.Size()

---
--~~~ lua
-- size = Size(width, height, depth)
--~~~
-- 
-- @tparam number width The width of the component.
-- @tparam number height The height of the component.
-- @tparam number depth The depth of the component.
function Size:_init(width, height, depth)
    self.width = width and width or 0
    self.height = height and height or 0
    self.depth = depth and depth or 0
end

function Size:__tostring()
    return string.format("<Size %0.3fw %0.3fh %0.3fd>", self.width, self.height, self.depth)
end

--- Creates and returns a copy of a given Size.
-- 
-- @treturn [Size](Size) A copy of the original Size object.
function Size:copy()
    return Size(self.width, self.height, self.depth)
end

--- Shrinks the Size component by the given parameters.
-- 
-- @tparam number byWidth The x component of the size reduction.
-- @tparam number byHeight The y component of the size reduction.
-- @tparam number byDepth The z component of the size reduction.
-- @treturn [Size](Size) The original Size object, post-resize.
function Size:inset(byWidth, byHeight, byDepth)
    self.width = self.width - byWidth
    self.height = self.height - byHeight
    self.depth = self.depth - byDepth
    return self
end

return Size
