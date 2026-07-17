local class = require "Tiled.class"

---@class AnimationFrame
---@field duration number Converted to Tiled.animationtimeunit
---@field tile Tile
---@field tileid integer The local ID of a tile within the parent <tileset>.

---@class Animation:Class
---@field duration number Total duration, in Tiled.animationtimeunit
---@field loopframe integer Frame index that should follow the last one. 0 = hold the last frame. -1 = last frame - 1, etc. Default is 1.
---@field [integer] AnimationFrame
local Animation = class()

function Animation:_init(tileset)
    local animationtimescale = 60/1000--AnimationTimeUnits[Assets.animationtimeunit] or 1
    local totalduration = 0
    for f = 1, #self do
        local frame = self[f]
        local duration = frame.duration
        totalduration = totalduration + duration
        frame.duration = duration * animationtimescale
        frame.tile = tileset[frame.tileid]
    end
    self.duration = totalduration * animationtimescale
    self.loopframe = 1
    return self
end

function Animation:clampIndex(i)
    if i <= 0 then
        i = #self + i
    end
    return math.max(1, math.min(i, #self))
end

function Animation:setLoopFrame(loopframe)
    self.loopframe = self:clampIndex(loopframe)
end

function Animation:isFinished(i, t)
    local duration = self[i].duration
    while t >= duration do
        t = t - duration
        i = i + 1
        if i > #self then
            return true
        end
        duration = self[i].duration
    end
end

function Animation:getUpdate(i, t, loopi)
    loopi = loopi or self.loopframe
    local duration = self[i].duration
    while t >= duration do
        t = t - duration
        if (i >= #self) then
            if i == loopi then
                break
            end
            i = loopi
        else
            i = i + 1
        end
        duration = self[i].duration
    end
    return i, t
end

return Animation