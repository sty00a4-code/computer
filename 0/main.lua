--- REQUIREMENTS
--- modem on the one side to the chest array
--- chest next to the computer on any side expect the chest arrays side

---@class Item : { name: string, count: integer, slots?: integer[][] }
---@class Chest
---@field list fun(): Item[]
---@field size fun(): integer
---@field getItemDetail function
---@field getItemLimit function
---@field pushItems function
---@field pullItems function
local function chests()
    ---@type Chest[]
    local chests = {}
    ---@type Chest
    local output = {}
    ---@class Chests
    local funcs = {
        reload = function ()
            local new = { peripheral.find("minecraft:chest") }
            output = table.remove(new)
            chests = new
        end,
        ---@return Chest[]
        chests = function ()
            return chests
        end,
        ---@return Chest
        chest = function (index)
            return chests[index]
        end,
        ---@return integer
        size = function ()
            local size = 0
            for _, chest in ipairs(chests) do
                size = size + chest.size()
            end
            return size
        end,
        ---@return table<string, Item>
        items = function ()
            local items = {}
            for id, chest in ipairs(chests) do
                for i, item in ipairs(chest.list()) do
                    if items[item.name] then
                        items[item.name].count = items[item.name].count + item.count
                        table.insert(items[item.name].slots[id], i)
                    else
                        items[item.name] = item
                        items[item.name].slots = {}
                        items[item.name].slots[id] = {i}
                    end
                end
            end
            return items
        end,
        ---@return Item[]
        list = function ()
            local items = {}
            ---@type string[]
            local index = {}
            for id, chest in ipairs(chests) do
                for i, item in ipairs(chest.list()) do
                    table.insert(index, item.name)
                    if items[item.name] then
                        items[item.name].count = items[item.name].count + item.count
                        table.insert(items[item.name].slots[id], i)
                    else
                        items[item.name] = item
                        items[item.name].slots = {}
                        items[item.name].slots[id] = {i}
                    end
                end
            end
            for i, name in ipairs(index) do
                index[i] = items[name]
            end
            return index
        end,
        ---@param index integer
        ---@param slot integer
        ---@return Item
        getItemDetail = function (index, slot)
            return chests[index].getItemDetail(slot)
        end,
        ---@param index integer
        ---@param slot integer
        ---@return integer
        getItemLimit = function (index, slot)
            return chests[index].getItemLimit(slot)
        end,
        ---pushes items at `fromSlot` from the output chest to the chest at `index` (at `toSlot` or any)
        ---@param index integer
        ---@param fromSlot integer
        ---@param limit? integer
        ---@param toSlot? integer
        pushItems = function (index, fromSlot, limit, toSlot)
            chests[index].pushItems(peripheral.getName(output), fromSlot, limit, toSlot)
        end,
        ---pulls items at `fromSlot` in chest at `index` into the output chest (at `toSlot` or any)
        ---@param index integer
        ---@param fromSlot integer
        ---@param limit? integer
        ---@param toSlot? integer
        pullItems = function (index, fromSlot, limit, toSlot)
            output.pullItems(peripheral.getName(chests[index]), fromSlot, limit, toSlot)
        end,
    }
    ---@param name string
    ---@param limit? integer
    ---@return boolean
    function funcs.pullItem(name, limit)
        local items = funcs.items()
        local item = items[name]
        if item then
            for index, slots in ipairs(item.slots) do
                if (limit or 0) <= 0 then
                    break
                end
                for _, slot in ipairs(slots) do
                    funcs.pullItems(index, slot, limit)
                    if limit then
                        limit = limit - funcs.getItemDetail(index, slot).count
                    end
                end
            end
            return true
        end
        return false
    end
    funcs.reload()
    return funcs
end
---@param chests Chests
---@return UI
local function ui(chests)
    local W, H = term.getSize()
    local list = {}
    local scroll = 0
    local selected
    local input = {
        text = "",
        prefi = "",
    }
    ---@class UI
    local funcs = {
        handlers = {},
    }
    function funcs.event(event, ...)
        local handler = funcs.handlers[event]
        if type(handler) == "function" then
            return handler(...)
        end
    end
    function funcs.update()
        if scroll < 0 then
            scroll = 0
        end
        if scroll > #list - H - 2 then
            scroll = #list - H - 2
        end
    end
    function funcs.draw()
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        term.clear()
        term.setCursorPos(1, 1)
        term.setBackgroundColor(colors.gray)
        term.clearLine()
        term.write(chests.size())
    end
    function funcs.run()
        while true do
            funcs.update()
            funcs.draw()
            ---@diagnostic disable-next-line: undefined-field
            funcs.event(os.pullEvent())
        end
    end
    funcs.handlers["char"] = function (char)
        if char == "r" then
            chests.reload()
        end
    end
    funcs.handlers["peripheral"] = function ()
        chests.reload()
    end
    funcs.handlers["peripheral_detach"] = funcs.handlers["peripheral"]
    funcs.handlers["term_size"] = function ()
        W, H = term.getSize()
    end
    return funcs
end

---@type Chests
local chests = chests()
local ui = ui(chests)
ui.run()