local class = require "Aseprite.class"
local Cel   = require "Aseprite.Cel"
local love_graphics_draw = love.graphics.draw

---@class AsePoint
---@field x number
---@field y number

---@class AseSize
---@field w number
---@field h number

---@class AseRect:AsePoint,AseSize

---@class AseFrame
---@field index integer
---@field image love.Texture
---@field frame AseRect
---@field rotated boolean
---@field trimmed boolean
---@field spriteSourceSize AseRect
---@field sourceSize AseSize
---@field duration number
---@field slices {[string]:AseSlice}?
---@field [integer] AseCel|false
local AseFrame = class()

function AseFrame:_init(i, image, duration, aseslices)
    self.index = i
    self.image = image
    self.duration = duration or 0
    if aseslices then
        local slices = {}
        self.slices = slices
        for _, slice in ipairs(aseslices) do
            if slice.keys[i] then
                slices[slice.name] = slice
            end
        end
    end
end

function AseFrame:putCel(i, cel)
    local rect = cel.frame
    local pos = cel.spriteSourceSize
    for h = #self+1, i-1 do
        self[h] = false
    end
    self[i] = Cel(self.image, pos, rect)
end

function AseFrame:drawCels(i, j, x, y)
    for l = i, j do
        local cel = self[l]
        if cel then
            love_graphics_draw(cel.image, cel.quad,
                (x or 0) + cel.x, (y or 0) + cel.y)
        end
    end
end
local drawCels = AseFrame.drawCels

function AseFrame:draw(x, y)
    drawCels(self, 1, #self, x, y)
end

function AseFrame:getSliceOrigin(name)
    local slice = self.slices and self.slices[name]
    if slice then
        return slice:getFrameOrigin(self.index)
    end
end

return AseFrame