local mod = setmetatable({}, {
    __name = "module.deepnet"
})

---Waits for a message to be received by the computer of `id`, then returns the received message
---@param id integer
---@param protocol? string
---@param timeout? number
---@return any
---@return string
function mod.receiveFrom(id, protocol, timeout)
    if type(id) ~= "number" then
        error(("expected argument #1 to be of type number, not " .. type(id)), 2)
    end
    local resvId, msg, resvProtocol
    repeat
        resvId, msg, resvProtocol = rednet.receive(protocol, timeout)
        if type(resvId) == "nil" then
            break
        end
    until resvId == id
    return msg, resvProtocol
end

---opens all connected wireless modems
function mod.open()
    peripheral.find("modem", function(name)
        return rednet.open(name)
    end)
end

---enters a dialogue with the computer `id`
---@param id integer
---@param init any
---@param handle fun(msg: any, protocol?: string): boolean
---@param protocol string?
function mod.enterPipe(id, init, handle, protocol)
    if not rednet.isOpen() then
        mod.open()
    end
    if type(init) ~= "nil" then
        rednet.send(id, init, protocol)
    end
    while true do
        local msg, protocol = mod.receiveFrom(id, protocol)
        if handle(msg, protocol) then
            return
        end
    end
end

---hosts a service with the given methods, protocol and a name
---@param protocol string
---@param name string
---@param service { handle: fun(id: integer, msg: any), update?: function, draw?: function, event?: fun(name: string, ...) }
function mod.startService(protocol, name, service)
    if not rednet.isOpen() then
        mod.open()
    end
    rednet.host(protocol, name)
    while true do
        if service.update then
            local msg = service.update()
            if type(msg) ~= "nil" then
                rednet.broadcast(msg)
            end
        end
        if service.draw then
            service.draw()
        end
        ---@diagnostic disable-next-line: undefined-field
        local event = { os.pullEvent() }
        if event[1] == "rednet_message" and event[4] == protocol then
            table.remove(event, 1)
            local msg = service.handle(unpack(event))
            if type(msg) ~= "nil" then
                rednet.send(event[2], msg, protocol)
            end
        elseif service.event then
            service.event(unpack(event))
        end
    end
end

return mod
