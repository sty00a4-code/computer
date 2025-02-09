require "typed"
local strings = require "cc.strings"
local mod = setmetatable({}, {
    __name = "module.cui"
})
local NULL = setmetatable({}, { __name = "null", __tostring = function () return "null" end })
mod.null = NULL

function string.split(s, sep)
    local parts = {}
    local temp = ""
    local idx = 0
    while idx <= #s do
        if s:sub(idx, idx + #sep) == sep then
            if temp then
                table.insert(parts, temp)
                temp = ""
            end
            idx = idx + #sep
        else
            temp = temp .. s:sub(idx, idx)
            idx = idx + 1
        end
    end
    if temp then
        table.insert(parts, temp)
        temp = ""
    end
    return parts
end

---@alias cc.ColorNames "white"|"orange"|"magenta"|"lightBlue"|"yellow"|"lime"|"pink"|"gray"|"lightGray"|"cyan"|"purple"|"blue"|"brown"|"green"|"red"|"black"
---@alias cc.ColorValues 1|2|4|8|16|32|64|128|512|1024|2048|4096|8192|16384|32768
---@alias cc.PaintColors "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"a"|"b"|"c"|"d"|"e"|"f"
---@type table<cc.ColorNames, cc.ColorValues>
colors = colors
---@param v? string|number
local function colorValue(v)
    if type(v) == "string" then
        return colors[v]
    end
    return v
end

---@alias cui.NewMethod<T, O> fun(opts: T, children: cui.Child[]): O
---@alias cui.DrawMethod<T> fun(self: T, area: cui.Area)
---@alias cui.EventMethod<T> fun(self: T, kind: string, ...): ...
---@alias cui.UpdateMethod<T> fun(self: T)
---@alias cui.Child cui.Element|string|fun(self: cui.Element): cui.Element|string

---@class cui.Area : { x: integer, y: integer, w: integer, h: integer }
local Area = class("cui.area", {
    ---@param self cui.Area
    ---@param x integer
    ---@param y integer
    ---@param w integer
    ---@param h integer
    __new = function(self, x, y, w, h)
        errorCheckType(x, 1, "number")
        errorCheckType(y, 2, "number")
        errorCheckType(w, 3, "number", "null")
        errorCheckType(h, 4, "number", "null")
        self.x, self.y, self.w, self.h = x, y, w, h
    end,
    __tostring = function(self)
        return ("Area(%s %s %s %s)"):format(self.x, self.y, self.w, self.h)
    end
})
---@type fun(x: integer, y: integer, w: integer, h: integer): cui.Area
---@diagnostic disable-next-line: assign-type-mismatch
mod.area = Area

---@class cui.ElementConfig : table
---@field margin? number
---@field padding? number
---@field limit? { width: { max: number, min: number, type: "percent"|"integer" }, height: { max: number, min: number, type: "percent"|"integer" } }

---@class cui.Element : { draw: cui.DrawMethod, event: cui.EventMethod, update: cui.UpdateMethod }
---@field config cui.ElementConfig
---@field children cui.Child[]
---@field draw cui.DrawMethod<cui.Element>
---@field event cui.EventMethod<cui.Element>
---@field update cui.UpdateMethod<cui.Element>
---@field drawString fun(child: string, area: cui.Area)
local Element = class("cui.element", {
    ---@param self cui.Element
    ---@param config cui.ElementConfig
    ---@param children cui.Child[]
    __new = function(self, config, children)
        errorCheckType(config, 1, "table")
        errorCheckType(children, 2, "table")
        self.config = config or {}
        errorCheckType(config.margin, "config.margin", "number", "nil")
        errorCheckType(config.padding, "config.padding", "number", "nil")
        errorCheckType(config.limit, "config.limit", "table", "nil")
        self.children = children or {}
    end,
    ---@param child string
    ---@param area cui.Area
    drawString = function (child, area)
        local lines = {}
        for _, line in ipairs(child:split("\n")) do
            local subLines = strings.wrap(line, area.w + 1)
            for _, line in ipairs(subLines) do
                table.insert(lines, line)
            end
        end
        for y, line in ipairs(lines) do
            if y > area.h then
                break
            end
            term.setCursorPos(area.x, area.y + y - 1)
            term.write(line)
        end
    end,
    ---@param self cui.Element
    ---@param area cui.Area
    draw = function(self, area)
        for _, child in pairs(self.children) do
            if type(child) == "function" then
                child = child(self)
            end
            if type(child) == "string" then
                self.drawString(child, area)
            else
                child:draw(area)
            end
        end
    end,
    event = function(self, ...)
        for _, child in pairs(self.children) do
            if type(child) == "function" then
                child = child(self)
            end
            if type(child) ~= "string" then
                child:event(...)
            end
        end
    end,
    update = function(self)
        for _, child in pairs(self.children) do
            if type(child) ~= "string" and type(child) ~= "function" then
                child:update()
            end
        end
    end,
})
---@type cui.NewMethod<table, cui.Element>
---@diagnostic disable-next-line: assign-type-mismatch
mod.element = Element

---@class cui.BoxConfig : cui.ElementConfig
---@field color? cc.ColorNames|cc.ColorValues
---@field fontColor? cc.ColorNames|cc.ColorValues
---@field border? "line"|"double"|string

---@class cui.Box : cui.Element
---@field config cui.BoxConfig
---@field draw fun(self: cui.Box, area: cui.Area)
---@field borderCode fun(self: cui.Box)
local Box = class("cui.box", {
    ---@param self cui.Box
    ---@param config cui.BoxConfig
    ---@param children cui.Child[]
    __new = function(self, config, children)
        ---@diagnostic disable-next-line: undefined-field
        Element.__new(self, config, children)
        errorCheckType(config.color, "config.color", "string", "number", "nil")
        errorCheckType(config.color, "config.border", "string", "nil")
    end,
    ---@param self cui.Box
    ---@param area cui.Area
    draw = function(self, area)
        term.setTextColor(colors.white)
        if self.config.fontColor then
            term.setTextColor(colorValue(self.config.fontColor))
        end
        paintutils.drawFilledBox(area.x, area.y, area.x + area.w - 1, area.y + area.h - 1, colorValue(self.config.color))
        if self.config.border then
            local code = self:borderCode()
            error("(TODO) box outline")
            Element.draw(self, Area(area.x + 1, area.y + 1, area.w - 2, area.h - 2))
        else
            Element.draw(self, area)
        end
    end,
    ---@param self cui.Box
    ---@return "--||...."|"==||####"|string
    borderCode = function(self)
        if self.config.border == "line" then
            return "--||...."
        elseif self.config.border == "double" then
            return "==||####"
        else
            return self.config.border
        end
    end
}, Element)
---@type cui.NewMethod<cui.BoxConfig, cui.Box>
---@diagnostic disable-next-line: assign-type-mismatch
mod.box = Box

---@class cui.LayoutConfig : table
---@field direction "vertical"|"horizontal"
---@field layout? number[]
---@class cui.Layout : cui.Element
---@field config cui.LayoutConfig
---@field draw fun(self: cui.Layout, area: cui.Area)
local Layout = class("cui.layout", {
    ---@param self cui.Layout
    ---@param config cui.LayoutConfig
    ---@param children cui.Child[]
    __new = function(self, config, children)
        ---@diagnostic disable-next-line: undefined-field
        Element.__new(self, config, children)
        errorCheckLiteral(config.direction, "config.direction", "vertical", "horizontal")
        errorCheckType(config.layout, "config.layout", "table", "nil")
    end,
    ---@param self cui.Layout
    ---@param area cui.Area
    draw = function(self, area)
        term.setTextColor(colors.white)
        if self.config.layout then
            local offset = 0
            for i, child in pairs(self.children) do
                local size = self.config.layout[i]
                if size then
                    if type(child) == "function" then
                        child = child(self)
                    end
                    local subArea
                    if self.config.direction == "horizontal" then
                        subArea = mod.area(area.x + offset, area.y, size, area.h)
                    else
                        subArea = mod.area(area.x, area.y + offset, area.w, size)
                    end
                    if type(child) == "string" then
                        self.drawString(child, subArea)
                    else
                        child:draw(subArea)
                    end
                    offset = offset + size
                end
            end
        else
            local each
            if self.config.direction == "horizontal" then
                each = area.w / #self.children
            else
                each = area.h / #self.children
            end
            for i, child in pairs(self.children) do
                if type(child) == "function" then
                    child = child(self)
                end
                local subArea
                if self.config.direction == "horizontal" then
                    subArea = mod.area(area.x + (i - 1) * each, area.y, each, area.h)
                else
                    subArea = mod.area(area.x, area.y + (i - 1) * each, area.w, each)
                end
                if type(child) == "string" then
                    self.drawString(child, subArea)
                else
                    child:draw(subArea)
                end
            end
        end
    end,
}, Element)
---@type cui.NewMethod<cui.LayoutConfig, cui.Layout>
---@diagnostic disable-next-line: assign-type-mismatch
mod.layout = Layout

return mod
