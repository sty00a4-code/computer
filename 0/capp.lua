local mod = setmetatable({}, {
    __name = "module.capp"
})

local App
---@class capp.App
---@field stack Program[]
App = {
    meta = {
        __name = "app"
    }
}
function App.new()
    return setmetatable({
        stack = {},
        call = App.call,
        exit = App.exit,
        program = App.program,
        event = App.event,
        run = App.run,
    }, App.meta)
end
mod.app = App.new
---@param self capp.App
---@param program Program
function App:call(program)
    table.insert(self.stack, program)
end
---@param self capp.App
---@return Program?
function App:exit()
    return table.remove(self.stack)
end
---@param self capp.App
---@return Program?
function App:program()
    return self.stack[#self.stack]
end
---@param self capp.App
function App:event(name, ...)
    local program = self:program()
    if not program then
        return
    end
    if type(program.events) == "function" then
        return program.events(self, name, ...)
    end
    local handle = program.events[name]
    if handle then
        local ret = handle(self, ...)
        return type(ret) == "nil" and true or ret
    elseif name == "terminate" then
        error "Terminated"
    else
        return false
    end
end
---@param self capp.App
---@param program Program
function App:run(program)
    self:call(program)
    ---@type Program?
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

local Program
Program = {
    meta = {
        __name = "app"
    }
}
function Program.new(opts)
    ---@alias capp.UpdateMethod fun(app: capp.App)
    ---@alias capp.DrawMethod fun(app: capp.App)
    ---@alias capp.EventHandle fun(app: capp.App, ...)
    ---@class Program : { update: capp.UpdateMethod?, draw: capp.DrawMethod?, events: table<string, capp.EventHandle>|capp.EventHandle }
    return setmetatable({
        update = opts.update,
        draw = opts.draw,
        events = opts.events or {},
        event = Program.event,
    }, Program.meta)
end
mod.program = Program.new

return mod
