require "typed"
require "class"
local mod = setmetatable({}, {
    __name = "module.cui"
})

---@alias cui.NewMethod<T> fun(opts: cui.Options, children: cui.Child[])
---@alias cui.DrawMethod<T> fun(self: T, area: cui.Area)
---@alias cui.EventMethod<T> fun(self: T, kind: string, ...)
---@alias cui.UpdateMethod<T> fun(self: T)
---@alias cui.Child cui.Element|string
---@alias cui.Options table<string, any>

---@class cui.Area : { x: integer, y: integer, w: integer, h: integer }
local Area = class("cui.area", {
    __new = function(self, x, y, w, h)
        errorCheckType(x, 2, "number")
        errorCheckType(y, 3, "number")
        errorCheckType(w, 4, "number")
        errorCheckType(h, 5, "number")
        self.x, self.y, self.w, self.h = x, y, w, h
    end
})
mod.area = Area

---@class cui.Element : { draw: cui.DrawMethod, event: cui.EventMethod, update: cui.UpdateMethod }
---@field opts cui.Options
---@field children cui.Child[]
local Element = class("cui.element", {
    ---@param self cui.Element
    ---@param opts cui.Options
    ---@param children cui.Child[]
    __new = function(self, opts, children)
        errorCheckType(opts, 2, "table")
        errorCheckType(children, 3, "table")
        self.opts = opts or {}
        self.children = children or {}
    end,
    draw = function(self, area)
        for _, child in pairs(self.children) do
            child:draw(area)
        end
    end,
    event = function(self, ...)
        for _, child in pairs(self.children) do
            child:event(...)
        end
    end,
    update = function() end,
})
---@type cui.NewMethod<cui.Element>
---@diagnostic disable-next-line: assign-type-mismatch
mod.element = Element

---@class cui.Box : cui.Element
local Box = class("cui.box", {
    draw = function(self, area)
        paintutils.drawBox(area.x, area.y, area.w, area.h)
        Element.draw(self, area)
    end,
}, Element)
---@type cui.NewMethod<cui.Box>
---@diagnostic disable-next-line: assign-type-mismatch
mod.box = Box

return mod
