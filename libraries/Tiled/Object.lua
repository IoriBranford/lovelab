local class = require "Tiled.class"
local Gid = require "Tiled.Gid"
local Assets = require "Tiled.Assets"
local Properties = require "Tiled.Properties"
local Color      = require "Tiled.Color"
local Graphics   = require "Tiled.Graphics"
local pathlite   = require "Tiled.pathlite"

---@class TiledObject:Class
---@field id integer Unique ID of the object (defaults to 0, with valid IDs being at least 1). Each object that is placed on a map gets a unique id. Even if an object was deleted, no object gets the same ID. Can not be changed in Tiled. (since Tiled 0.11)
---@field name string The name of the object. An arbitrary string. (defaults to “”)
---@field type string The class of the object. An arbitrary string. (defaults to “”, was saved as class in 1.9)
---@field class string? The class of the object when saved/exported in Tiled 1.9. An arbitrary string. (defaults to “”)
---@field x number The x coordinate of the object in pixels. (defaults to 0)
---@field y number The y coordinate of the object in pixels. (defaults to 0)
---@field z number Drawing order, default is objectgroup's z, set with object property "z" (float)
---@field width number The width of the object in pixels. (defaults to 0)
---@field height number The height of the object in pixels. (defaults to 0)
---@field rotation number The rotation of the object in **radians** clockwise around (x, y). (defaults to 0)
---@field scalex number Object scale x, based on gid flipx and tile width
---@field scaley number Object scale y, based on gid flipy and tile height
---@field gid integer? A reference to a tile. (optional)
---@field visible boolean Whether the object is shown (1) or hidden (0). (defaults to 1)
---@field template string? A reference to a template file. (optional)
---@field shape "rectangle"|"ellipse"|"polyline"|"polygon"|"point"|"text"|"particlesystem"|"aseprite"
---@field points number[]? Converted to array [x1, y1, x2, y2, x3, y3, ...]
---@field triangles number[]? Triangle coordinates if polygon - 6 per triangle
---@field layer ObjectGroup?
---@field tile Tile?
---@field animationframe integer?
---@field animationtime integer?
---@field animationquad love.Quad?
---@field animationspeed number?
---@field particlesystem love.ParticleSystem?
---@field properties table? These get moved into object itself
---@field color Color?
---@field linecolor Color?
---@field loopframe integer? Override for tile animation's loopframe
---@field originx number? Override of tile's objectoriginx
---@field originy number? Override of tile's objectoriginy
---@field skewx number?
---@field skewy number?
---@field linewidth number? Line thickness for lines and polygons
---@field velx number? Used with dt param in draw() to smooth movement at any framerate
---@field vely number? Used with dt param in draw() to smooth movement at any framerate
---@field shader love.Shader?
---@field [string] any Custom property
local TiledObject = class()

---@class ParticleSystemObject:TiledObject
---@field shape "particlesystem"
---@field particlesystem love.ParticleSystem
---@field tile Tile
---@field maxparticles integer? Initial particle buffer size
---@field lifetime number? Initial min lifetime, defaults to animation duration, or 1 second if no animation
---@field maxlifetime number? Initial max lifetime
---@field speed number? Initial minimum speed
---@field maxspeed number? Initial maximum speed
---@field lineardamping number? Initial minimum linear damping
---@field maxlineardamping number? Initial maximum linear damping
---@field spread number? Initial spread in radians. Has priority over spreaddegrees
---@field spreaddegrees number? Initial spread in degrees. Recommended way to set spread in Tiled due to low precision of float properties. Overridden by spread
---@field accelx number? Initial linear acceleration x
---@field accely number? Initial linear acceleration y
---@field areadistribution love.AreaSpreadDistribution? Initial area distribution
---@field areadx number? Initial area dx
---@field aready number? Initial area dy
---@field directionmode "fromcenter"?

---@class TextObject:TiledObject
---@field shape "text"
---@field text string
---@field string string Copy of text
---@field fontfamily string The font family used (defaults to “sans-serif”)
---@field pixelsize integer The size of the font in pixels (not using points, because other sizes in the TMX format are also using pixels) (defaults to 16)
---@field wrap boolean Whether word wrapping is enabled (1) or disabled (0). (defaults to 0)
---@field color Color Color of the text in #AARRGGBB or #RRGGBB format (defaults to #000000). Exported as RGBA256 array in Lua
---@field bold boolean Whether the font is bold (1) or not (0). (defaults to 0)
---@field italic boolean Whether the font is italic (1) or not (0). (defaults to 0)
---@field underline boolean Whether a line should be drawn below the text (1) or not (0). (defaults to 0)
---@field strikeout boolean Whether a line should be drawn through the text (1) or not (0). (defaults to 0)
---@field kerning boolean Whether kerning should be used while rendering the text (1) or not (0). (defaults to 1)
---@field halign string Horizontal alignment of the text within the object (left, center, right or justify, defaults to left) (since Tiled 1.2.1)
---@field valign string Vertical alignment of the text within the object (top , center or bottom, defaults to top)
---@field font love.Font Loaded font object
--- Font file should be in Tiled.fontpath and follow this naming:
--- "fontfamily.ttf"
--- "fontfamily Bold.ttf"
--- "fontfamily Italic.ttf"
--- "fontfamily Bold Italic.ttf"
--- "fontfamily [pixelsize].fnt"
--- "fontfamily Bold [pixelsize].fnt"
--- "fontfamily Italic [pixelsize].fnt"
--- "fontfamily Bold Italic [pixelsize].fnt"
---@field backcolor Color Color to fill the rectangle behind the text in #AARRGGBB or #RRGGBB format (defaults to #000000)
---@field bordercolor Color  Color to outline the rectangle around the text in #AARRGGBB or #RRGGBB format (defaults to #000000)

---@class AsepriteObject:TiledObject
---@field aseprite Aseprite
---@field aseanimation AseTag?
---@field asefile string
---@field asetag string?

local function triangulate(points)
    local cantriangulate, triangles = pcall(love.math.triangulate, points)
    if cantriangulate then
        local tris = {}
        for i = 1, #triangles do
            local triangle = triangles[i]
            for i = 1, #triangle do
                tris[#tris+1] = triangle[i]
            end
        end
        return tris
    end
    return false, triangles
end

local function processPoly(object)
    local poly = object.polygon or object.polyline
    if poly then
        local points = {}
        object.points = points
        local offsetx, offsety = -poly[1].x, -poly[1].y
        object.x = object.x - offsetx
        object.y = object.y - offsety
        for i = 1, #poly do
            local point = poly[i]
            local px = point.x
            local py = point.y
            points[#points+1] = px + offsetx
            points[#points+1] = py + offsety
        end
        if object.shape == "polygon" then
            local errormsg
            object.triangles, errormsg = triangulate(points)
            if not object.triangles then
                print("Object "..(object.id or object), errormsg)
            end
        end
    end
end

function TiledObject:_init(map)
    if map then
        Properties.resolveAssetPaths(self.properties, map.directory)
        Properties.resolveObjectRefs(self.properties, map.objects)
    end
    Properties.moveUp(self)

    if self.visible == nil then
        self.visible = true
    end
    local objecttype = self.class or self.type or ""
    self.type = objecttype
    local gid = self.gid
    local tile = self.tile
    local maptiles = map and map.tiles
    local flipx, flipy = 1, 1
    if maptiles and gid then
        gid, flipx, flipy = Gid.parse(gid)
        tile = maptiles[gid]
    end
    if tile then
        self:initTile(tile, flipx, flipy)
    else
        local shape = self.shape
        if shape == "rectangle" then
            self.draw = self.drawRectangle
        elseif shape == "ellipse" then
            self.draw = self.drawEllipse
        elseif shape == "polyline" then
            self.draw = self.drawLine
        elseif shape == "polygon" then
            self.draw = self.drawPolygon
        end
    end
    processPoly(self)
    self:initText()

    if self.asefile and not self.aseprite then
        self:initAseprite(map and map.directory)
    end

    return self
end

function TiledObject:setVisible(visible)
    self.visible = visible
end

---@param tile Tile
function TiledObject:initTile(tile, flipx, flipy)
    flipx = flipx or 1
    flipy = flipy or 1
    if tile then
        local width = self.width or tile.width
        local height = self.height or tile.height
        self.scalex = self.scalex or (flipx * (width / tile.width))
        self.scaley = self.scaley or (flipy * (height / tile.height))
        if (self.type or "") == "" then
            self.type = tile.type
        end
        if tile.imagetype == "aseprite" then
            self.asefile = tile.tileset.imagefile
            self:initAseprite()
            return
        end
    end
    self.animate = self.animateTile
    self.draw = self.drawTile
    self:setTile(tile)
end

---@param self AsepriteObject|TiledObject
---@param directory string?
function TiledObject:initAseprite(directory)
    local asefile = self.asefile
    if not asefile then
        return
    end
    if (directory or "") ~= "" then
        asefile = pathlite.normjoin(directory, asefile)
        self.asefile = asefile
    end
    local ase = Assets.get(asefile)
    local tag = self.asetag
    self.aseprite = ase
    self:setAseAnimation(ase and tag and ase.animations[tag], 1, self.loopframe)
    self.animate = self.animateAseprite
    self.draw = self.drawAseprite
end

---@param self TextObject|TiledObject
function TiledObject:initText()
    local text = self.text
    if text then
        if type(self.color) == "table" then
            self.color = Color.asARGBInt(Color.normalize(self.color))
        end
        local font = Assets.getFont(self.fontfamily, self.pixelsize, self.bold, self.italic)
        self.font = font
        self.draw = self.drawText
    end
end

local initParticleSystem_quads = {}

---@param self ParticleSystemObject
function TiledObject:initParticleSystem()
    local tile = self.tile
    if not tile then
        return
    end

    local particlesystem = love.graphics.newParticleSystem(tile.image, self.maxparticles or 1000)
    self.shape = "particlesystem"
    self.particlesystem = particlesystem
    self.animate = self.animateParticleSystem
    self.draw = self.drawParticleSystem

    local quads = initParticleSystem_quads
    local animation = tile.animation
    local lifetime = self.lifetime
    if animation then
        lifetime = lifetime or animation.duration

        for i, frame in ipairs(animation) do
            quads[i] = frame.tile.quad
        end
        particlesystem:setQuads(quads)
        for i = #quads, 1, -1 do
            quads[i] = nil
        end
    else
        particlesystem:setQuads(tile.quad)
    end

    lifetime = lifetime or 60
    particlesystem:setParticleLifetime(lifetime, self.maxlifetime or lifetime)

    if self.speed then
        particlesystem:setSpeed(self.speed, self.maxspeed or self.speed)
    end
    if self.lineardamping then
        particlesystem:setLinearDamping(self.lineardamping, self.maxlineardamping or self.lineardamping)
    end
    local spread = self.spread or self.spreaddegrees and math.rad(self.spreaddegrees)
    if spread then
        particlesystem:setSpread(spread)
        self.spread = spread
    end
    local accelx, accely = self.accelx, self.accely
    if accelx or accely then
        particlesystem:setLinearAcceleration(accelx or 0, accely or 0)
    end

    local dist = self.areadistribution
    if dist then
        local dx, dy = self.areadx or 0, self.aready or 0
        particlesystem:setEmissionArea(dist, dx, dy, spread or 0, self.directionmode == "fromcenter")
    end

    return particlesystem
end

---@param self TiledObject|AsepriteObject
function TiledObject:isAnimationEnding(dt)
    local animation = self.tile and self.tile.animation or self.aseanimation or self.aseprite
    if animation then
        local aframe = self.animationframe
        local aspeed = self.animationspeed or 1
        local atime = self.animationtime + dt*aspeed
        return animation:isFinished(aframe, atime)
    end
end

function TiledObject:animate(dt)
end

function TiledObject:animateTile(dt)
    local tile = self.tile
    if not tile then return end

    local animation = tile.animation
    if animation then
        local aframe = self.animationframe
        local atime = self.animationtime
        local aloop = self.loopframe
        local aspeed = self.animationspeed or 1

        aframe, atime = animation:getUpdate(aframe, atime + dt*aspeed, aloop)
        self.animationframe = aframe
        self.animationtime = atime
        self.animationquad = animation[aframe].tile.quad
    end
end

---@param self AsepriteObject
function TiledObject:animateAseprite(dt)
    local animation = self.aseanimation
    if not animation then return end

    local aframe = self.animationframe
    local atime = self.animationtime
    local aloop = self.loopframe
    local aspeed = self.animationspeed or 1

    aframe, atime = animation:getUpdate(aframe, atime + dt*aspeed, aloop)
    self.animationframe = aframe
    self.animationtime = atime
end

---@param self TiledObject|AsepriteObject
---@return (AnimationFrame|AseFrame)?
function TiledObject:getAnimationFrame()
    local animation = self.tile and self.tile.animation
        or self.aseanimation or self.aseprite
    return animation and animation[self.animationframe]
end

function TiledObject:getAnimationTile()
    local frame = self:getAnimationFrame()
    return frame and frame.tile or self.tile
end

function TiledObject:animateParticleSystem(dt)
    self.particlesystem:update(dt)
end

---@param key integer|string
function TiledObject:getAnimationTileShape(key)
    local tile = self:getAnimationTile()
    if not tile then return end
    local shapes = tile.shapes
    return shapes and shapes[key]
end

function TiledObject:getTileRect()
    local x, y, w, h = self.x, self.y, self.width, self.height
    local tile = self.tile
    local ox, oy = 0, 0
    if tile then
        ox, oy = tile.objectoriginx, tile.objectoriginy
        w = w or tile.width
        h = h or tile.height
    end
    return x - ox, y - oy, w, h
end

function TiledObject:setTile(tile, frame1, loopframe)
    if type(tile) ~= "table" then
        local oldtile = self.tile
        tile = oldtile and oldtile.tileset[tile]
    end
    if not tile then return end
    self.tile = tile
    self.animationtime = 0
    self.animationquad = nil
    local animation = tile.animation
    if animation then
        frame1 = frame1 and animation:clampIndex(frame1)
        loopframe = loopframe and animation:clampIndex(loopframe)
    end
    self.animationframe = frame1 or 1
    self.loopframe = loopframe
end
local setTile = TiledObject.setTile

function TiledObject:changeTile(newtile)
    local tile = self.tile
    if type(newtile) ~= "table" then
        newtile = tile and tile.tileset[newtile]
    end
    if newtile and newtile ~= tile then
        setTile(self, newtile)
    end
end

function TiledObject:randomizeTile()
    local tile = self.tile
    if not tile then return end
    local tileid = love.math.random(#tile.tileset)
    local newtile = tile.tileset[tileid]
    setTile(self, newtile)
end

function TiledObject:setAseAnimation(animation, frame1, loopframe)
    if type(animation) == "string" then
        animation = self.aseprite and self.aseprite.animations[animation]
    end
    if not animation then
        return
    end
    self.aseanimation = animation
    self.animationtime = 0

    if animation then
        frame1 = frame1 and animation:clampIndex(frame1)
        loopframe = loopframe and animation:clampIndex(loopframe)
    end
    self.animationframe = frame1 or 1
    self.loopframe = loopframe
end

function TiledObject:changeAseAnimation(animation, frame1, loopframe)
    local aseprite = self.aseprite
    if type(animation) == "string" then
        animation = aseprite and aseprite.animations[animation]
    end
    if animation and animation ~= self.aseanimation then
        self:setAseAnimation(animation, frame1, loopframe)
    end
end

function TiledObject:changeAnimation(animation, frame1, loopframe)
    if self.aseprite then
        self:changeAseAnimation(animation, frame1, loopframe)
    elseif self.tile then
        self:changeTile(animation)
    end
end

function TiledObject:setAnimation(animation, frame1, loopframe)
    if self.aseprite then
        self:setAseAnimation(animation, frame1, loopframe)
    elseif self.tile then
        self:setTile(animation, frame1, loopframe)
    end
end

function TiledObject:getTileset()
    local tile = self.tile
    return tile and tile.tileset
end

function TiledObject:getExtents()
    local x, y = self.x, self.y
    local points = self.points
    if points then
        local px1, py1, px2, py2 = math.boundingbox(points)
        return x + px1, y + py1, x + px2, y + py2
    end
    local drawable = self.aseprite or self.tile
    if drawable then
        local sx = self.scalex or 1
        local sy = self.scaley or 1
        local ox = self.originx or drawable.objectoriginx or 0
        local oy = self.originy or drawable.objectoriginy or 0
        local x1 = x - ox * sx
        local y1 = y - oy * sy
        local x2 = x1 + drawable.width  * sx
        local y2 = y1 + drawable.height * sy
        return x1, y1, x2, y2
    end
    return x, y, x + (self.width or 0), y + (self.height or 0)
end

function TiledObject:getWorldPosition()
    local layerx, layery = self.layer:getWorldPosition()
    return self.x + layerx, self.y + layery
end

function TiledObject:move(dx, dy)
    self.x, self.y = self.x + dx, self.y + dy
end

local pushTransform = Graphics.pushTransform

function TiledObject:drawTile(fixedfrac)
    local tile = self.tile
    if not tile then return end
    local r,g,b,a = Color.unpack(self.color)
    love.graphics.setColor(r,g,b,a)
    local velx, vely = self.velx or 0, self.vely or 0
    fixedfrac = fixedfrac or 0
    love.graphics.draw(tile.image,
        self.animationquad or tile.quad,
        (self.x + velx * fixedfrac),
        (self.y + vely * fixedfrac),
        self.rotation,
        self.scalex or 1, self.scaley or 1,
        self.originx or tile.objectoriginx, self.originy or tile.objectoriginy,
        self.skewx or 0, self.skewy or 0)
end

function TiledObject:drawLine()
    pushTransform(self)

    local r,g,b,a = Color.unpack(self.color)
    love.graphics.setColor(r,g,b,a)
    love.graphics.setLineWidth(self.linewidth or 1)
    love.graphics.line(self.points)

    love.graphics.pop()
end

function TiledObject:drawPolygon()
    pushTransform(self)

    local color = self.color
    local linecolor = self.linecolor
    local r,g,b,a = Color.unpack(color)
    local triangles = self.triangles
    if triangles then
        love.graphics.setColor(r,g,b,a)
        for i = 6, #triangles, 6 do
            love.graphics.polygon("fill",
                triangles[i-5], triangles[i-4],
                triangles[i-3], triangles[i-2],
                triangles[i-1], triangles[i-0])
        end
    else
        linecolor = linecolor or color or Color.White
    end
    if linecolor then
        r,g,b,a = Color.unpack(linecolor)
        love.graphics.setColor(r,g,b,a)
        love.graphics.setLineWidth(self.linewidth or 1)
        love.graphics.polygon("line", self.points)
    end

    love.graphics.pop()
end

local function drawAsColorRect(self, color, mode)
    local r,g,b,a = Color.unpack(color)
    love.graphics.setColor(r,g,b,a)
    local x, y = 0, 0
    if mode == "line" then
        x, y = .5, .5
    end
    love.graphics.rectangle(mode, x, y, self.width or 2, self.height or 2, self.roundcorners or 0)
end

function TiledObject:drawRectangle()
    pushTransform(self)
    drawAsColorRect(self, self.color, "fill")
    if self.linecolor then
        drawAsColorRect(self, self.linecolor, "line")
    end
    love.graphics.pop()
end

function TiledObject:drawEllipse()
    pushTransform(self)

    local hw, hh = (self.width or 2)/2, (self.height or 2)/2

    local r,g,b,a = Color.unpack(self.color)
    love.graphics.setColor(r,g,b,a)
    love.graphics.ellipse("fill", hw, hh, hw, hh)

    if self.linecolor then
        r,g,b,a = Color.unpack(self.linecolor)
        love.graphics.setColor(r,g,b,a)
        love.graphics.ellipse("line", hw, hh, hw, hh)
    end

    love.graphics.pop()
end

---@param self TextObject
function TiledObject:drawText(fixedfrac)
    local backcolor, bordercolor = self.backcolor, self.bordercolor
    if backcolor or bordercolor then
        pushTransform(self)
    end
    if backcolor then
        drawAsColorRect(self, backcolor, "fill")
    end
    if bordercolor then
        drawAsColorRect(self, bordercolor, "line")
    end
    if backcolor or bordercolor then
        love.graphics.pop()
    end

    local r,g,b,a = Color.unpack(self.color)
    love.graphics.setColor(r,g,b,a)
    local font = self.font or love.graphics.getFont()
    local str = self.text
    local velx, vely = self.velx or 0, self.vely or 0
    fixedfrac = fixedfrac or 0
    local x, y = self.x + velx * fixedfrac, self.y + vely * fixedfrac
    local lineh = font:getHeight()
    local w, h = self.width or love.graphics.getWidth(), self.height or lineh
    local _, lines = font:getWrap(str, w)
    local n = #lines
    local valign = self.valign
    if valign == "bottom" then
        y = y + h - lineh*n
    elseif valign == "center" then
        y = y + (h - lineh*n) / 2
    end
    for i = 1, n do
        love.graphics.printf(lines[i], font, x, y,
            w, self.halign,
            self.rotation,
            self.scalex, self.scaley,
            self.originx or 0, self.originy or 0,
            self.skewx or 0, self.skewy or 0)
        y = y + lineh
    end
end

---@param self ParticleSystemObject
function TiledObject:emitParticles(x, y, num, direction)
    local particlesystem = self.particlesystem
    if not particlesystem then return end

    particlesystem:moveTo(x, y)
    if direction then
        particlesystem:setDirection(direction)
    end
    particlesystem:emit(num)
end

function TiledObject:drawParticleSystem()
    local r,g,b,a = Color.unpack(self.color)
    love.graphics.setColor(r,g,b,a)
    love.graphics.draw(self.particlesystem)
end

function TiledObject:getOrigin()
    local originx, originy = self.originx, self.originy
    if originx and originy then return originx, originy end

    if self.aseprite then
        ---@cast self AsepriteObject
        local animation = self.aseanimation

        if animation then
            local aframe = self.animationframe or 1
            local frame = animation[aframe]
            if frame then
                originx, originy = frame:getSliceOrigin("origin")
                if originx and originy then return originx, originy end
            end

            originx, originy = animation[1]:getSliceOrigin("origin")
            if originx and originy then return originx, originy end
        end

        originx, originy = self.aseprite[1]:getSliceOrigin("origin")
        if originx and originy then return originx, originy end
    end

    if self.tile then
        return self.tile.objectoriginx, self.tile.objectoriginy
    end

    return 0, 0
end

---@param self AsepriteObject
function TiledObject:drawAseprite(fixedfrac)
    local animation = self.aseanimation or self.aseprite
    local aframe = self.animationframe or 1
    local frame = animation and animation[aframe]
    if not frame then
        return
    end

    local r,g,b,a = Color.unpack(self.color)
    love.graphics.setColor(r,g,b,a)

    local velx, vely = self.velx or 0, self.vely or 0
    fixedfrac = fixedfrac or 0

    local x, y = self.x + velx*fixedfrac, self.y + vely*fixedfrac
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(self.rotation or 0)
    love.graphics.shear(self.skewx or 0, self.skewy or 0)
    love.graphics.scale(self.scalex or 1, self.scaley or 1)

    local originx, originy = self:getOrigin()
    love.graphics.translate(-originx, -originy)

    frame:draw()
    love.graphics.pop()
end

function TiledObject:draw()
end

return TiledObject
