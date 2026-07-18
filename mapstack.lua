math1 = require "math123.math1"
math2 = require "math123.math2"
math3 = require "math123.math3"
class = require "Tiled.class"
local Assets = require "Tiled.Assets"

local Tiled = require "Tiled"
local FS = love.filesystem

---@class MapStack
---@field [integer] TiledMap
---@field [string] integer file->index
local MapStack = {}
MapStack.__index = MapStack

local maps = {}

function MapStack.load(mapfile)
    if not FS.getInfo(mapfile, "file") then
        return nil, "Map file not found "..mapfile
    end
    local map = Tiled.Map.load(mapfile, {
        withclasses=true,
        index="all"
    })
    return map
end

function MapStack.getMap(map)
    local mapt = type(map)
    if mapt == "string" then
        map = maps[map] or MapStack.load(map)
    elseif mapt == "number" then
        map = maps[map]
    end
    return map
end

function MapStack.reload(mapfile)
    local i = maps[mapfile]
    if not i then return end

    Assets.maps[mapfile] = nil
    local map, err = MapStack.load(mapfile)
    if not map then return nil, err end

    maps[i] = map
    return map
end

function MapStack.push(map)
    local i = #maps+1
    maps[i] = map
    maps[map.file] = i
    return i
end

function MapStack.pop()
    local top = maps[#maps]
    maps[#maps] = nil
    maps[top.file] = nil
    return top
end

local function event(i1, i2, di, ev, a, b, c, d, e, f)
    for i = i1, i2, di do
        local map = maps[i]
        local fn = map[ev]
        if type(fn) == "function" then
            local u, v, w, x, y, z
                = fn(map, a, b, c, d, e, f)
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

function MapStack.inevent(e, ...)
    event(1, #maps, 1, e, ...)
end

function MapStack.outevent(e, ...)
    event(#maps, 1, -1, e, ...)
end

function MapStack.empty()
    return #maps <= 0
end

return MapStack