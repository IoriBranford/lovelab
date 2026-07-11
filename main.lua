require "math1"
require "table.new"
local fixed_timestep = require "fixed_timestep"
local math2          = require "math2"

---@diagnostic disable-next-line: duplicate-set-field
function love.load()
    love.window.setVSync(-1)
    Points = table.new(2*10*360, 0)
    local r1, r2, d = 60, 100, 100
    local dr = r2-r1
    local drDr = dr/r1
    local sr = r1+r2
    local srDr = sr/r1
    for i = 1, 360*3 do
        local a = math.rad(i)
        local cosa = math.cos(a)
        local sina = math.sin(a)

        local aXdrDr = a*drDr
        local cosaXdrDr = math.cos(aXdrDr)
        local sinaXdrDr = math.sin(aXdrDr)
        local x = dr*cosa + d*cosaXdrDr
        local y = dr*sina - d*sinaXdrDr
        Points[#Points+1] = x
        Points[#Points+1] = y
    end
    -- for i = 1, 360*5 do
    --     local a = math.rad(i)
    --     local cosa = math.cos(a)
    --     local sina = math.sin(a)

    --     local aXsrDr = a*srDr
    --     local cosaXsrDr = math.cos(aXsrDr)
    --     local sinaXsrDr = math.sin(aXsrDr)
    --     local x = sr*cosa - d*cosaXsrDr
    --     local y = sr*sina - d*sinaXsrDr
    --     Points[#Points+1] = x
    --     Points[#Points+1] = y
    -- end
    I = 2
    X = Points[1]
    Y = Points[2]
    Speed = 20
    FrameLerp = 0
    FixedTimestep = fixed_timestep(10)
    require("lldebugger").start()
end
-- This function is called exactly once at the beginning of the game.

---@diagnostic disable-next-line: duplicate-set-field
function love.update(dt)
    FrameLerp = FixedTimestep(dt, function()
        X, Y, I = math2.walkpolyline(Points, X, Y, I, Speed)
        if I <= 2 or I >= #Points then
            Speed = -Speed
        end
    end)
end
-- Callback function used to update the state of the game every frame.

---@diagnostic disable-next-line: duplicate-set-field
function love.draw()
    love.graphics.translate(love.graphics.getWidth()/2, love.graphics.getHeight()/2)
    love.graphics.setColor(1,1,1)
    love.graphics.line(Points)

    local x, y = math2.walkpolyline(Points, X, Y, I, Speed*FrameLerp)
    local t = love.timer.getTime()*256
    love.graphics.setColor(love.math.random(),love.math.random(),love.math.random())
    -- local lx, ly = math2.frompolar(t, 16)
    -- love.graphics.line(x-lx, y-ly, x+lx, y+ly)
    love.graphics.circle("fill", x, y, 10)
end
-- Callback function used to draw on the screen every frame.

---@diagnostic disable-next-line: duplicate-set-field
function love.quit()

end
-- Callback function triggered when the game is closed.
