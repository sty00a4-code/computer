local mod = setmetatable({}, {
    __name = "module.deepnet"
})

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

function mod.open()
    peripheral.find("modem", function(name)
        return rednet.open(name)
    end)
end

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

function mod.startService(service, protocol)
    if not rednet.isOpen() then
        mod.open()
    end
    while true do
        if service.update then
            service.update()
        end
        if service.draw then
            service.draw()
        end
        ---@diagnostic disable-next-line: undefined-field
        local event = { os.pullEvent() }
        if event[1] == "rednet_message" and event[4] == protocol then
            table.remove(event, 1)
            service.handle(unpack(event))
        elseif service.event then
            service.event(unpack(event))
        end
    end
end

return mod
