local tnew = require "table.new"

---@alias listener table

---@class listeners
---@field [integer] listener|false
---@field free integer[]?

---@class dispatch
---@field [string] listeners
local dispatch = {}
dispatch.__index = dispatch

function dispatch.new(...)
    local self = tnew(0, 16) ---@type dispatch
    setmetatable(self, dispatch)
    for i = 1, select("#", ...) do
        local ev = select(i, ...)
        self:newevent(ev)
    end
    return self
end

function dispatch:newevent(ev)
    if not self[ev] then
        self[ev] = tnew(8, 1)
    end
end

---Subscribe
---@param ev string
---@param l listener
---@return integer i
function dispatch:sub(ev, l, after)
    assert(type(l[ev]) == "function")

    self:newevent(ev)
    local ls = self[ev]

    local free = ls.free
    local i = not after and
        free and free[#free]
        or (#ls+1)
    if free then free[#free] = nil end

    ls[i] = l
    return i
end

function dispatch:allsub(l, after, force)
    local sub = self.sub
    if force then
        for ev, f in pairs(l) do
            if type(f) == "function" then
                l[ev.."sub"] = sub(self, ev, l, after)
            end
        end
    else
        for ev, f in pairs(l) do
            if self[ev] and type(f) == "function" then
                l[ev.."sub"] = sub(self, ev, l, after)
            end
        end
    end
end

---Unsubscribe
---@param ev string
---@param i integer
---@param l listener?
function dispatch:unsub(ev, i, l)
    local ls = self[ev]
    if not ls then return end

    if l then assert(l == ls[i]) end

    local free = ls.free or tnew(8, 0)
    ls.free = free
    free[#free+1] = i
    ls[i] = false
end

function dispatch:allunsub(l)
    local unsub = self.unsub
    for ev in pairs(l) do
        local i = l[ev.."sub"]
        if i then
            unsub(self, ev, i, l)
            l[ev.."sub"] = nil
        end
    end
end

function dispatch:clearev(ev)
    self[ev] = nil
end

local function send(ls, i1, i2, di, ev, ...)
    for i = i1, i2, di do
        local l = ls[i]
        if l then l[ev](...) end
    end
end

local function sendself(ls, i1, i2, di, ev, ...)
    for i = i1, i2, di do
        local l = ls[i]
        if l then l[ev](l, ...) end
    end
end

function dispatch:send(ev, ...)
    local ls = self[ev]
    if ls then send(ls, 1, #ls, 1, ev, ...) end
end

function dispatch:rsend(ev, ...)
    local ls = self[ev]
    if ls then send(ls, #ls, 1, -1, ev, ...) end
end

function dispatch:sendself(ev, ...)
    local ls = self[ev]
    if ls then sendself(ls, 1, #ls, 1, ev, ...) end
end

function dispatch:rsendself(ev, ...)
    local ls = self[ev]
    if ls then sendself(ls, #ls, 1, -1, ev, ...) end
end

return dispatch