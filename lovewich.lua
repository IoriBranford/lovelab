local type = type
local pcall = pcall
local require = require
local getmetatable = getmetatable
local cocreate = coroutine.create
local coresume = coroutine.resume
local costatus = coroutine.status
local loadfile = love and love.filesystem.load or loadfile

---@alias eventerror string in the form eventname.."error"

---@class lovewich.ftable
---@field [string] function|eventerror
---@field eventco thread?

---@class lovewich
---@field [integer] lovewich.ftable
---@field files table<string, fun(...):lovewich.ftable>
-----@field results table<integer>
local lovewich = {}
lovewich.__index = lovewich

function lovewich.new()
    return setmetatable({files = {}}, lovewich)
end

function lovewich:pushfile(file, ...)
    local f = self.files[file]
    if f then
        local ft = f(...)
        self[#self+1] = ft
        return ft
    end
    return self:loadandpushfile(file, ...)
end

function lovewich:loadandpushfile(file, ...)
    local f, err = loadfile(file)
    if not f then return nil, err end
    self.files[file] = f
    local ft = f(...)
    if type(ft) ~= "table" then
        return nil, file.." must return a function table"
    end
    self[#self+1] = ft
    return ft
end

function lovewich:pushmodule(module, ...)
    local ok, m = pcall(require, module)
    if not ok then return ok, m end
    local tm = type(m)
    local ft = tm == "table" and m
        or tm == "function" and m(...)
    if not ft then
        return nil, module.." must return a function or table"
    end
    self[#self+1] = ft
    return ft
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

---@param ft lovewich.ftable
---@param ev string
---@param co thread
local function coeventi(ft, ev, co,
                            a, b, c, d, e, f)
    local ok, u, v, w, x, y, z
        = coresume(co, a, b, c, d, e, f)
    if not ok then
        ft[ev.."error"] = u
        return a, b, c, d, e, f
    end
    if costatus(co) ~= "dead" then
        ft.eventco = co
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

---@param self lovewich
local function coevent(self, i1, i2, di,
                        ev, a, b, c, d, e, f)
    for i = i1, i2, di do
        local ft = self[i]
        local fn = ft[ev]
        if type(fn) == "function" then
            local co = cocreate(fn)
            a, b, c, d, e, f =
                coeventi(ft, ev, co,
                    a, b, c, d, e, f)
        end
    end
    for i = #suspended, 1, -1 do
        local ft = suspended[i]
        local co = assert(ft.eventco)
        ft.eventco = nil
        local ok, err = coresume(co, a, b, c, d, e, f)
        if not ok then
            ft[ev.."error"] = err
        end
    end
    return a, b, c, d, e, f
end

function lovewich:coevout(e, ...)
    coevent(self, 1, #self, 1, e, ...)
end

function lovewich:coevin(e, ...)
    coevent(self, #self, 1, -1, e, ...)
end

function lovewich:evout(e, ...)
    event(self, 1, #self, 1, e, ...)
end

function lovewich:evin(e, ...)
    event(self, #self, 1, -1, e, ...)
end

function lovewich:empty()
    return #self <= 0
end

return lovewich