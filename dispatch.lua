local tnew = require "table.new"

---@alias listener table<string, function>

---@class listeners
---@field [integer] listener|false
---@field free table<integer, true>?

---@class dispatch
---@field [string] listeners
local dispatch = {}
dispatch.__index = dispatch

function dispatch.new()
    local self = tnew(0, 16) ---@type dispatch
    setmetatable(self, dispatch)
    return self
end

---Subscribe
---@param ev string
---@param l listener
---@return integer i
function dispatch:sub(ev, l, after)
    assert(type(l[ev]) == "function")

    local ls = self[ev] or tnew(16, 1)
    self[ev] = ls

    local free = ls.free
    local i = not after and
        free and next(free)
        or (#ls+1)
    if free then free[i] = nil end

    ls[i] = l
    return i
end

---Unsubscribe
---@param ev string
---@param i integer
---@param l listener?
function dispatch:unsub(ev, i, l)
    local ls = self[ev]
    if not ls then return end

    if l then assert(l == ls[i]) end

    local free = ls.free or tnew(0, 16)
    ls.free = free
    free[i] = true
    ls[i] = false
end

function dispatch:clearev(ev)
    self[ev] = nil
end

local function send(ls, i1, i2, di, ev, ...)
    for i = i1, i2, di do
        if ls[i] then ls[i][ev](...) end
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

return dispatch