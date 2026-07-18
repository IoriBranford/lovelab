local type = type
local cocreate = coroutine.create
local coresume = coroutine.resume
local costatus = coroutine.status
local loadfile = love and love.filesystem.load or loadfile

---@class lovewich.ftable
---@field [string] function
---@field co thread?
---@field eventerror string?

---@class lovewich
---@field [integer] lovewich.ftable
---@field files table<string, fun(...):lovewich.ftable>
-----@field results table<integer>
local lovewich = {}
lovewich.__index = lovewich

function lovewich.new()
    return setmetatable({files = {}}, lovewich)
end

function lovewich:pushf(file, ...)
    local f = self.files[file]
    if f then return self:push(f(...)) end
    return self:loadf(file, ...)
end

function lovewich:loadf(file, ...)
    local _, f = pcall(loadfile, file)
    if type(f) ~= "function" then return nil, f end
    self.files[file] = f
    return self:push(f(...))
end

function lovewich:pushm(module, ...)
    local ok, m = pcall(require, module)
    if not ok then return nil, m end
    return self:push(m(...))
end

---@param ft lovewich.ftable
---@return integer
function lovewich:push(ft)
    local i = #self+1
    self[i] = ft
    return i
end

function lovewich:pop()
    local top = self[#self]
    self[#self] = nil
    return top
end

local function event(self, i1, i2, di, ev, a, b, c, d, e, f)
    for i = i1, i2, di do
        local ft = self[i]
        local fn = ft[ev]
        if type(fn) == "function" then
            local u, v, w, x, y, z
                = fn(a, b, c, d, e, f)
            if u ~= nil then a = u end
            if v ~= nil then b = v end
            if w ~= nil then c = w end
            if x ~= nil then d = x end
            if y ~= nil then e = y end
            if z ~= nil then f = z end
        end
    end
    return a, b, c, d, e, f
end

local suspended = {} ---@type lovewich.ftable[]

local function coevent1(ft, ev, co, a, b, c, d, e, f)
    local ok, u, v, w, x, y, z
        = coresume(co, a, b, c, d, e, f)
    if not ok then
        ft[ev.."error"] = u
        return a, b, c, d, e, f
    end
    if costatus(co) ~= "dead" then
        ft.co = co
        suspended[#suspended+1] = ft
    end
    if u ~= nil then a = u end
    if v ~= nil then b = v end
    if w ~= nil then c = w end
    if x ~= nil then d = x end
    if y ~= nil then e = y end
    if z ~= nil then f = z end
    return a, b, c, d, e, f
end

local function coevent(self, i1, i2, di, ev, a, b, c, d, e, f)
    for i = i1, i2, di do
        local ft = self[i]
        local fn = ft[ev]
        if type(fn) == "function" then
            local co = cocreate(fn)
            a, b, c, d, e, f = coevent1(ft, ev, co, a, b, c, d, e, f)
        end
    end
    for i = #suspended, 1, -1 do
        local ft = suspended[i]
        local co = assert(ft.co)
        ft.co = nil
        local ok, err = coresume(co)
        if not ok then
            ft[ev.."error"] = err
        end
    end
    return a, b, c, d, e, f
end

function lovewich:cooutevent(e, ...)
    coevent(self, 1, #self, 1, e, ...)
end

function lovewich:outevent(e, ...)
    event(self, 1, #self, 1, e, ...)
end

function lovewich:inevent(e, ...)
    event(self, #self, 1, -1, e, ...)
end

function lovewich:empty()
    return #self <= 0
end

return lovewich