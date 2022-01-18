--- TabView: Switch between different UIs using tabs
-- @classmod TabView

local modules = (...):gsub(".[^.]+.[^.]+$", '') .. "."
local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local vec3 = require("modules.vec3")
local mat4 = require("modules.mat4")
local Bounds = require(modules .."bounds")
local Size = require(modules .."size")
local View = require(modules .."views.view")
local Button = require(modules .."views.button")
local Base64Asset = require(modules.."asset.init").Base64

class.TabViewItem()
function TabViewItem:_init(view, name, button)
    self.view = view
    self.name = name
    self.button = button
end

class.TabView(View)

---
--~~~ lua
-- tabView = TabView(bounds)
--~~~
--@tparam [Bounds](bounds) bounds The TabView's bounds.
function TabView:_init(bounds)
    self:super(bounds)
    self.tabs = {} --TabViewItem
    self.currentTabIndex = 0

    self.textColor = {0,0,0,1.0}
    self.inactiveColor = {0.75, 0.75, 0.75, 1.0}
    self.activeColor =   {0.75, 0.9, 0.9, 1.0}

    local barHeight = math.min(0.1, bounds.size.height/10.0)
    local barBounds = bounds:copy()
        :insetEdges(0, 0, 0, bounds.size.height - barHeight, 0, 0)
    self.tabBar = self:addSubview(ui.StackView(barBounds, "horizontal"))
end

function TabView:addTab(name, view)
    -- figure out how wide the new tab bar button should be
    local tabCount = #self.tabs + 1
    local buttonBounds = self.tabBar.bounds:copy()
    buttonBounds.size.width = buttonBounds.size.width / tabCount

    -- resize existing buttons
    for i, b in ipairs(self.tabBar.subviews) do
        b.bounds.size = buttonBounds.size:copy()
        b:markAsDirty("transform")
    end

    -- add the new button
    local button = ui.Button(buttonBounds)
    button.label:setText(name)
    button.label:setColor(self.textColor)
    button:setColor(self.inactiveColor)
    button.onActivated = function()
        self:switchToTabIndex(tabCount)
    end
    self.tabBar:addSubview(button)
    self.tabBar:layout()

    -- add the new item
    local item = TabViewItem(view, name, button)
    table.insert(self.tabs, item)

    -- resize the view to fit the tab view
    local viewBounds = self.bounds:copy():insetEdges(0, 0, self.tabBar.bounds.size.height, 0, 0, 0)
    view:setBounds(viewBounds)

    -- if we don't have a selected tab, make the new one the selected one
    if #self.tabs == 1 then
        self:switchToTabIndex(1)
    end
    return view, #self.tabs
end

function TabView:switchToTabIndex(index)
    local newTab = self.tabs[index]
    local oldTab = self.currentTabIndex > 0 and self.tabs[self.currentTabIndex] or nil
    if index == self.currentTabIndex then
        return
    end
    self.currentTabIndex = index

    if newTab then
        self:addSubview(newTab.view)
        newTab.button:setColor(self.activeColor)
    end
    if oldTab then 
        oldTab.view:removeFromSuperview()
        oldTab.button:setColor(self.inactiveColor)
    end
end

function TabView:getCurrentTabIndex()
    return self.currentTabIndex
end

return TabView
