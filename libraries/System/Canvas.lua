---@class Canvas
---@field shader love.Shader?
---@overload fun(width:integer, height:integer, inputscale:number?):Canvas
local Canvas = class()

function Canvas:_init(basewidth, baseheight, inputscale)
    self.rotscale = love.math.newTransform()
    self.transform = love.math.newTransform()
    self:resize(basewidth, baseheight, inputscale)
end

function Canvas:resize(basewidth, baseheight, inputscale)
    inputscale = inputscale or 1
    basewidth, baseheight = math.floor(basewidth*inputscale), math.floor(baseheight*inputscale)
    local cw, ch, filtered
    if self.canvas then
        cw, ch = self.canvas:getDimensions()
        filtered = self.canvas:getFilter() ~= "nearest"
    end
    if cw ~= basewidth or ch ~= baseheight then
        self.canvas = love.graphics.newCanvas(basewidth, baseheight)
        self:setFiltered(filtered)
    end
    self.rotscale:reset()
    self.transform:reset()
    self.inputscale = inputscale
end

function Canvas.Scaled(basew, baseh, screenw, screenh, screenrot, round, inputscale)
    inputscale = inputscale or 1
    local canvas = Canvas(basew, baseh, inputscale)
    canvas:transformToScreen(screenw, screenh, screenrot, round)
    return canvas
end

function Canvas.ForAnotherCanvas(basew, baseh, screenw, screenh, other)
    local canvas = Canvas(basew, baseh, other.inputscale)
    canvas:transformToAnotherCanvas(screenw, screenh, other)
    return canvas
end

function Canvas.GetScaleFactor(fromwidth, fromheight, towidth, toheight, rotation, round)
    local scale
    if rotation and math.abs(math.sin(rotation)) > math.sqrt(2)/2 then
        scale = math.min(toheight / fromwidth, towidth / fromheight)
    else
        scale = math.min(towidth / fromwidth, toheight / fromheight)
    end

    if round and scale >= 1 then
        if round ~= math.ceil then
            round = math.floor
        end
        scale = round(scale)
    end
    return scale
end

function Canvas:getBaseWidth()
    return self.canvas:getWidth()/self.inputscale
end

function Canvas:getBaseHeight()
    return self.canvas:getHeight()/self.inputscale
end

function Canvas:transformToScreen(screenwidth, screenheight, rotation, round)
    local canvas = self.canvas
    local ghw = screenwidth / 2
    local ghh = screenheight / 2
    local chw = canvas:getWidth() / 2
    local chh = canvas:getHeight() / 2

    local outputscale = Canvas.GetScaleFactor(canvas:getWidth(), canvas:getHeight(), screenwidth, screenheight, rotation, round)

    local rotscale = self.rotscale
    rotscale:reset()
    rotscale:rotate(rotation)
    rotscale:scale(outputscale)
    self.rotscale = rotscale

    local transform = self.transform
    transform:reset()
    transform:translate(math.floor(ghw), math.floor(ghh))
    transform:apply(rotscale)
    transform:translate(-chw, -chh)
end

function Canvas:transformToAnotherCanvas(screenwidth, screenheight, othercanvas)
    local ghw = screenwidth / 2
    local ghh = screenheight / 2
    local chw = self.canvas:getWidth() / 2
    local chh = self.canvas:getHeight() / 2

    local rotscale = self.rotscale:setMatrix("row",
        othercanvas.rotscale:getMatrix())

    local transform = self.transform
    transform:reset()
    transform:translate(math.floor(ghw), math.floor(ghh))
    transform:apply(rotscale)
    transform:translate(-chw, -chh)
end

function Canvas:setFiltered(filtered)
    local filter = filtered and "linear" or "nearest"
    self.canvas:setFilter(filter, filter)
end

function Canvas:drawOn(draw, arg, ...)
    if type(draw) == "table" and draw.canvas then
        draw, arg = Canvas.draw, draw
    end
    local oldcanvas = love.graphics.getCanvas()
    love.graphics.setCanvas(self.canvas)
    love.graphics.push()
    love.graphics.scale(self.inputscale)
    draw(arg, ...)
    love.graphics.pop()
    love.graphics.setCanvas(oldcanvas)
end

function Canvas:drawScaledTo(draw)
    love.graphics.push()
    love.graphics.applyTransform(self.transform)
    draw()
    love.graphics.pop()
end

function Canvas:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setShader(self.shader)
    love.graphics.draw(self.canvas, self.transform)
end

function Canvas:inverseTransformVector(vecx, vecy)
    local inputscale = self.inputscale
    vecx, vecy = self.rotscale:inverseTransformPoint(vecx, vecy)
    vecx, vecy = vecx/inputscale, vecy/inputscale
    return vecx, vecy
end

function Canvas:inverseTransformPoint(x, y)
    local inputscale = self.inputscale
    x, y = self.transform:inverseTransformPoint(x, y)
    x, y = x/inputscale, y/inputscale
    return x, y
end

function Canvas:transformVector(vecx, vecy)
    local inputscale = self.inputscale
    vecx, vecy = vecx*inputscale, vecy*inputscale
    vecx, vecy = self.rotscale:transformPoint(vecx, vecy)
    return vecx, vecy
end

function Canvas:transformPoint(x, y)
    local inputscale = self.inputscale
    x, y = x*inputscale, y*inputscale
    x, y = self.transform:transformPoint(x, y)
    return x, y
end

return Canvas