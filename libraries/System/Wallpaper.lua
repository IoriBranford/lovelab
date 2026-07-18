local Config = require "System.Config"
local Wallpaper = {}

local wallpaper
local transform

function Wallpaper.reload()
    local gw = love.graphics.getWidth()
    local gh = love.graphics.getHeight()
    local ghw = gw / 2
    local ghh = gh / 2
    local scale
    local rotation = math.rad(Config.rotation)
    local portraitrotation = Config.isPortraitRotation()
    local backgroundstyle = Config.backgroundstyle
    local filename = Config.isVertical()
        and string.format("data/wallpaper/%s-vert.png", backgroundstyle)
         or string.format("data/wallpaper/%s-hori.png", backgroundstyle)
    wallpaper = love.filesystem.getInfo(filename) and love.graphics.newImage(filename)
    if not wallpaper then
        return
    end
    if portraitrotation then
        scale = math.max((gw / wallpaper:getHeight()), (gh / wallpaper:getWidth()))
    else
        scale = math.max((gw / wallpaper:getWidth()), (gh / wallpaper:getHeight()))
    end
    transform = love.math.newTransform(ghw, ghh, rotation, scale, scale, wallpaper:getWidth()/2, wallpaper:getHeight()/2)
end

function Wallpaper.draw()
    if wallpaper then
        love.graphics.draw(wallpaper, transform)
    end
end

return Wallpaper