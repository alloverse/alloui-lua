--- A widget for moving something; think of it as the title bar of a window.
-- Grabbing the title bar moves the window, not the title bar. Same here; set this
-- as the subview of your root view to make it movable. You can set any bounds on
-- this handle to position it at a good location in your view.
-- @classmod GrabHandle

local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local Surface = require(modules.."views.surface")


class.GrabHandle(Surface)
GrabHandle.assets = {
    image = Base64Asset("iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsIAAA7CARUoSoAAAAP+SURBVHhe7ZsLjpswEIZDol6k6lF6yp6lB2jVK1Q9x0ptROe3Z/BrbA8EdoHk0zoQM29sx9llh2+/fo6XHgMfq5K4IEIr0zONa/0MVO7jeLnyuc5A1sVB4SSOqhXhg4jpWpILkwc3yk8vgBilCukO0PmA5yVIIVaudSgA7jZAXlUnknQssDwir2nTn6RWrnsoAO42UOMJXkv/yyPymjb95V7atNcAcTuI2GC8X8ehUQAkz+nK6Cj42II85JvXt0YBGuaneozhVMVfhaW4rUXbt0akQWve2/1fbwpUcFmUyZX4XkjGzQ5bdUrzNEvI1phGWf8YzLAmtz5s1bnSo7BDtmACDWbp+Ol2sxVgveR2sIhy8pLUsikwh8gZTvRiSm96dXGxZihuUgCXBl6wucJqW/Ui1ZGI08jTcsyAFb211GaO6cvQ9z+/+ewYfP38hc/6dEfA0ZIHc2Lefg3YOZUCnG/LWyMUABlPq4FfrdE1Zz7thTkx0yL4g3KlVCXjCKUr4ArWlFgN58qf2kBGpGTRoRHACRR51KYBh+Os6xKPkYVNRc52sA1YcEZY2RoQO88D4aM7aXiofnO0QrZj86Zb6WWGSNAaBRdgZJ+xZ0YsKZcKIIuAH8Ua/QQp+Bq0kdAiQS5AXDvPlIYpH9ZeIfdNkSSjQmRTIOBl/TpQa4H03f7Iby9DYZ98K4zU2jenOgKEY2+F+yPziiLtfQCvh0zs0K54TebASaqhp+F7ka+0dApIb8RRt8JZGlV4EaSf1oZDfrFxUOLR4LPAq++d9gFq8tKXJK8JfjxIJ040BhFL8wRJ5VMAF1lUtcidNW8b4dyxT+0WpAmW1MINBZjuMo7BE85U5Za3DXDu2GctmZxYrhZuKMBVvv1FanQKxUdyXRJsE46ppOy1xB2NAFGwqNmxWjN7JcGkWNMbcwkTXr8V5mOVY2+FO9DHeyjAshF0bGjhT9aAZ6Q7BY66FbZiWgTPTHcEnBe/6D1HAdQF3g/85yhAY5I/8RTwPH0BXlthPlY59VaYeK0BfHxOaPJ3C3DqrTDtD15bYT5W8Zuo3kPRdv7e71PbA90C+MSXPjQVaXEF8XyutPdHnoMIbLwIRuNmaP+pHW17sucgyOk7fgr4adRqFhYXKvvLlrMzGh+XN0cHuY1vZRqKJTCSQUzZoztes/d/g4I1KchZYlqNTmDurpNMI6Z3nAIb0Mof17K7XmKdAjvD5YbGo9u/ZJhGYj4FMGQKRc0SeTQ56KH56wOVuJltKCMiLQAECplKeV03XqzeNXJ/bCsyicuJiBVSKiLLPgnAzCmQG8D7pZskDbYUGYSHMuwIbZ6jj5Qscc0sgG4yCVCp8jZwhpo/cwyXy3+J0TAitxbCpAAAAABJRU5ErkJggg==")
}

---
--
--~~~ lua
-- grab_handle = GrabHandle(bounds)
--~~~
--
-- @tparam [Bounds](bounds) bounds The GrabHandle's bounds.

function GrabHandle:_init(bounds)
    self:super(bounds)
    self.texture = GrabHandle.assets.image
    self.rotationConstraint = {0, 1, 0}
end

function GrabHandle:specification()
    local s = self.bounds.size
    local w2 = s.width / 2.0
    local h2 = s.depth / 2.0
    local mySpec = tablex.union(Surface.specification(self), {
        collider= {
            type= "box",
            width= s.width, height= s.height, depth= s.depth
        },
        grabbable= {
            actuate_on= "$parent",
            rotation_constraint= self.rotationConstraint
        }
    })
    return mySpec
end

return GrabHandle
