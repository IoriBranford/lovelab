---@param x number tip bottom position x
---@param y number tip bottom position y
---@param r number slice radius
---@param h number slice height
---@param angle number direction angle of the arc center
---@param arc number arc size
local function drawCake(x, y, r, h, angle, arc)
    if arc >= math.pi then
        love.graphics.circle("line", x, y, r)
        love.graphics.circle("line", x, y - h, r)
        love.graphics.line(x + r, y, x + r, y - h)
        love.graphics.line(x - r, y, x - r, y - h)
    else
        love.graphics.arc("line", x, y, r, angle - arc, angle + arc)
        love.graphics.arc("line", x, y - h, r, angle - arc, angle + arc)
        local c1, s1 = r*math.cos(angle-arc), r*math.sin(angle-arc)
        local c2, s2 = r*math.cos(angle+arc), r*math.sin(angle+arc)
        love.graphics.line(x + c1, y + s1, x + c1, y + s1 - h)
        love.graphics.line(x + c2, y + s2, x + c2, y + s2 - h)
        local c = math.cos(angle)
        local d = math.cos(arc)
        if c > d then
            love.graphics.line(x + r, y, x + r, y - h)
        elseif c < -d then
            love.graphics.line(x - r, y, x - r, y - h)
        end
    end
end

return drawCake