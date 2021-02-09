local modules = (...):gsub(".[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')

-- Size in meters of a view or element in the world
-- Note that size and scale are different things: size is the semantic size of your app
-- (e g "this button is 2 dm wide") while scale is the scaling up or down of this semantic
-- size (e g a transformation matrix with a 2.0 X-axis scale and a 2dm width is 4dm wide, but its
-- content is still 2dm wide.)
class.Size()
function Size:_init(width, height, depth)
    self.width = width and width or 0
    self.height = height and height or 0
    self.depth = depth and depth or 0
end

function Size:copy()
    return Size(self.width, self.height, self.depth)
end

function Size:inset(byWidth, byHeight, byDepth)
    self.width = self.width - byWidth
    self.height = self.height - byHeight
    self.depth = self.depth - byDepth
    return self
end

return Size
