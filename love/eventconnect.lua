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

---Connect specified events
---@param l listener
---@param after boolean
---@param ... string
function love.event.connectMult(l, after, ...)
    local connect = love.event.connect
    local n = select("#", ...)
    for i = 1, n do
        local ev = select(i, ...)
        l[ev.."conn"] = connect(ev, l, after)
    end
end

---Connect all of a table's functions to events
---@param l listener
---@param after boolean?
function love.event.connectAll(l, after)
    local connect = love.event.connect
    for ev, f in pairs(l) do
        if type(f) == "function" then
            l[ev.."conn"] = connect(ev, l, after)
        end
    end
end

---Disconnect from event
---@param ev string
---@param conn conn
---@param l listener?
function love.event.disconnect(ev, conn, l)
    Conns:unsub(ev, conn, l)
end

function love.event.clearConnections()
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

function love.event.send(ev, ...)
    Conns:send(ev, ...)
end
