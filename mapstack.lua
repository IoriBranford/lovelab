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

function MapStack.event(e, ...)
    for _, map in ipairs(maps) do
        local f = map[e]
        if type(f) == "function" then
            f(map, ...)
        end
    end
end

function MapStack.empty()
    return #maps <= 0
end

return MapStack