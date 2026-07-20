local lovewich = require "lovewich"

local LW = lovewich.new()

function love.load()
    LW:pushmodules("PixelScaler")
end

function love.draw()
    LW:upcb("draw_cb")
end