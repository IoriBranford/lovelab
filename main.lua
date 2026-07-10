local fixed_timestep = require "fixed_timestep"
local math2          = require "math2"
---@diagnostic disable-next-line: duplicate-set-field
function love.load()
    Points = {
        320,224,320,128,0,128,32,96,64,96,96,64,160,64,192,32,224,32,288,32,288,112,256,144,256,224
    }
    I = 2
    X = 0
    Y = 0
    Speed = 4
    FixedTimestep = fixed_timestep(60)
    require("lldebugger").start()
end
-- This function is called exactly once at the beginning of the game.

---@diagnostic disable-next-line: duplicate-set-field
function love.update(dt)
    FixedTimestep(dt, function()
        X, Y, I = math2.walkpolyline(Points, X, Y, I, 4)
    end)
end
-- Callback function used to update the state of the game every frame.

---@diagnostic disable-next-line: duplicate-set-field
function love.draw()
    love.graphics.setColor(1,1,1)
    love.graphics.line(Points)
    local t = love.timer.getTime()*1000
    local dx, dy = math2.frompolar(t, 16)
    love.graphics.setColor(love.math.random(),love.math.random(),love.math.random())
    love.graphics.line(X-dx, Y-dy, X+dx, Y+dy)
end
-- Callback function used to draw on the screen every frame.

---@diagnostic disable-next-line: duplicate-set-field
function love.quit()

end
-- Callback function triggered when the game is closed.
