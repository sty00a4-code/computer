local mod = setmetatable({}, {
    __name = "module.capp"
})
require "class"

---@class capp.App
---@field stack capp.Program[]
---@field call fun(self: capp.App, program: capp.Program)
---@field exit fun(self: capp.App): capp.Program?
---@field program fun(self: capp.App): capp.Program?
---@field event fun(self: capp.App, name: string, ...)
---@field run fun(self: capp.App, program: capp.Program)

---@type fun(): capp.App
---@diagnostic disable-next-line: assign-type-mismatch
mod.app = class("capp.app", {
    ---@param self capp.App
    __new = function(self)
        self.stack = {}
    end,
    ---@param self capp.App
    ---@param program capp.Program
    call = function(self, program)
        table.insert(self.stack, program)
    end,
    ---@param self capp.App
    ---@return capp.Program?
    exit = function(self)
        return table.remove(self.stack)
    end,
    ---@param self capp.App
    ---@return capp.Program?
    program = function(self)
        return self.stack[#self.stack]
    end,
    ---@param self capp.App
    ---@param name string
    ---@param ... any
    ---@return any
    event = function(self, name, ...)
        local program = self:program()
        if not program then
            return
        end
        if type(program.events) == "function" then
            return program.events(self, name, ...)
        end
        if type(program.events) == "table" then
            local handle = program.events[name]
            if handle then
                local ret = handle(self, ...)
                return type(ret) == "nil" and true or ret
            elseif name == "terminate" then
                error("Terminated", 3)
            else
                return false
            end
        end
    end,
    run = function(self, program)
        self:call(program)
        ---@type capp.Program?
        local program = self:program()
        while program do
            if program.update then
                program.update(self)
            end
            if program.draw then
                program.draw(self)
            end
            ---@diagnostic disable-next-line: undefined-field
            while not self:event(os.pullEventRaw()) do end
            program = self:program()
        end
    end
})

---@class capp.ProgramConfig
---@field update? fun(app: capp.App)
---@field draw? fun(app: capp.App)
---@field events? table<string, fun(app: capp.App, ...)>|fun(app: capp.App, name: string, ...)
---@class capp.Program
---@field update fun(app: capp.App)
---@field draw fun(app: capp.App)
---@field events table<string, fun(app: capp.App, ...)>|fun(app: capp.App, ...)

---@type fun(opts: capp.ProgramConfig): capp.Program
---@diagnostic disable-next-line: assign-type-mismatch
mod.program = class("capp.program", {
    ---@param self capp.Program
    ---@param opts capp.ProgramConfig
    __new = function (self, opts)
        self.update = opts.update
        self.draw = opts.draw
        self.events = opts.events or {}
    end
})

return mod
