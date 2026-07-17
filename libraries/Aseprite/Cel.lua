---@class AseCel
---@field x number
---@field y number
---@field width number
---@field height number
---@field image love.Texture
---@field imagetype "image"|"canvas"
---@field quad love.Quad
local Cel = class()

function Cel:_init(image, srcrect, destpos)
    self.x = srcrect.x
    self.y = srcrect.y
    self.width = srcrect.w
    self.height = srcrect.h
    self.image = image
    self.quad = love.graphics.newQuad(destpos.x, destpos.y, destpos.w, destpos.h, image:getWidth(), image:getHeight())
end

function Cel:draw(offsetx, offsety, r, sx, sy, ox, oy, kx, ky)
    love.graphics.draw(self.image, self.quad,
        (offsetx or 0) + self.x, (offsety or 0) + self.y,
        r or 0, sx or 1, sy or 1, ox, oy, kx, ky)
end

return Cel