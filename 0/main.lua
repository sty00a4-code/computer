--- REQUIREMENTS
--- modem on the one side to the chest array
--- chest next to the computer on any side expect the chest arrays side
local capp = require "capp"
local cui = require "cui"

if periphemu then
    periphemu.remove("chest_0")
    periphemu.remove("chest_1")
    periphemu.remove("chest_2")
    periphemu.remove("chest_3")
    periphemu.remove("chest_4")
    periphemu.remove("chest_5")
    periphemu.remove("right")
    periphemu.create("chest_0", "chest")
    periphemu.create("chest_1", "chest")
    periphemu.create("chest_2", "chest")
    periphemu.create("chest_3", "chest")
    periphemu.create("chest_4", "chest")
    periphemu.create("chest_5", "chest")
    periphemu.create("right", "chest")
    local chest = peripheral.wrap("chest_0")
    chest.setItem(1, { name = "iron_ingot", count = 64 })
    chest.setItem(2, { name = "iron_ingot", count = 64 })
    chest.setItem(3, { name = "iron_ingot", count = 64 })
    local chest = peripheral.wrap("chest_1")
    chest.setItem(1, { name = "iron_ingot", count = 64 })
    local chest = peripheral.wrap("chest_5")
    chest.setItem(1, { name = "steak", count = 10 })
end

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
        reload = function()
            local new = { peripheral.find("minecraft:chest") }
            output = table.remove(new)
            chests = new
        end,
        ---@return Chest[]
        chests = function()
            return chests
        end,
        ---@return Chest
        chest = function(index)
            return chests[index]
        end,
        ---@return integer
        size = function()
            local size = 0
            for _, chest in ipairs(chests) do
                size = size + chest.size()
            end
            return size
        end,
        ---@return table<string, Item>
        items = function()
            local items = {}
            for id, chest in ipairs(chests) do
                for i, item in ipairs(chest.list()) do
                    if items[item.name] then
                        items[item.name].count = items[item.name].count + item.count
                        table.insert(items[item.name].slots[id], i)
                    else
                        items[item.name] = item
                        items[item.name].slots = {}
                        items[item.name].slots[id] = { i }
                    end
                end
            end
            return items
        end,
        ---@return Item[]
        list = function()
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
                        items[item.name].slots[id] = { i }
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
        getItemDetail = function(index, slot)
            return chests[index].getItemDetail(slot)
        end,
        ---@param index integer
        ---@param slot integer
        ---@return integer
        getItemLimit = function(index, slot)
            return chests[index].getItemLimit(slot)
        end,
        ---pushes items at `fromSlot` from the output chest to the chest at `index` (at `toSlot` or any)
        ---@param index integer
        ---@param fromSlot integer
        ---@param limit? integer
        ---@param toSlot? integer
        pushItems = function(index, fromSlot, limit, toSlot)
            chests[index].pushItems(peripheral.getName(output), fromSlot, limit, toSlot)
        end,
        ---pulls items at `fromSlot` in chest at `index` into the output chest (at `toSlot` or any)
        ---@param index integer
        ---@param fromSlot integer
        ---@param limit? integer
        ---@param toSlot? integer
        pullItems = function(index, fromSlot, limit, toSlot)
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

---@type Chests
local chests = chests()
local app = capp.app()
local gui = cui.layout({
    direction = "vertical",
    layout = {
        1, 2
    }
}, {
    cui.box({
        color = "gray",
    }, {
        "1"
    }),
    cui.box({
        color = "green"
    }, {
        "2"
    }),
    cui.box({
        color = "blue",
    }, {
        "3"
    }),
    cui.box({
        color = "blue",
    }, {
        "4"
    }),
})
app:run(capp.program {
    draw = function(_)
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        term.clear()
        term.setCursorPos(1, 1)
        local area = cui.area(1, 1, term.getSize())
        gui:draw(area)
    end,
    events = function (_, name, ...)
        if name == "terminate" then
            error("Terminated", 3)
        end
        gui:event(name, ...)
    end
})