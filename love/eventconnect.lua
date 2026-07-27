local dispatch = require "dispatch"

local Conns = dispatch.new()

---@alias conn integer

---Connect to event
---@param ev string
---@param l listener
---@param after boolean?
---@return integer
function love.event.connect(ev, l, after)
    return Conns:sub(ev, l, after)
end

---Disconnect from event
---@param ev string
---@param conn conn
---@param l listener?
function love.event.disconnect(ev, conn, l)
    Conns:unsub(ev, conn, l)
end

function love.event.disconnectAll()
    Conns = dispatch.new()
end

function love.event.update()
    love.event.pump()
    for name, a,b,c,d,e,f in love.event.poll() do
        if name == "quit" then
            if not love.quit or not love.quit() then
                return "quit", a or 0
            end
        end
        Conns:send(name, a, b, c, d, e, f)
    end
end
