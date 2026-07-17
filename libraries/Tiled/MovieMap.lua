local Map = require "Tiled.Map"
local Movie = require "Tiled.Movie"
local mapstack = require "mapstack"

local Gfx = love.graphics

---@class MovieMap:TiledMap
---@field playingmovie Movie
local MovieMap = class(Map)

function MovieMap:_init(file)
    self.showoverlay = true
    self.time = 0
    self.pause = true
end

function MovieMap:fixedupdate()
    if not self.pause then
        self:step()
    end
end

function MovieMap:step()
    if not self.playingmovie
    or self.playingmovie:ended() then return end
    self.time = self.time + 1
    local ok, err = self.playingmovie:play()
    if not ok then
        self.movieerror = err
        print(err)
    end
end

function MovieMap:startMovie(i)
    local movie = self.layers[i]
    if not movie or not Movie.is(movie) then return end
    ---@cast movie Movie

    if self.playingmovie then
        local newself, err = mapstack.reload(self.file)
        if not newself then
            self.movieerror = err
            return
        end
        self = newself
    end
    self.playingmovie = self.layers[i]
    self.layers:showOnlyNamed(self.playingmovie.name)
    self.time = 0
    self.playingi = i
    self.movieerror = nil
    self.pause = love.keyboard.isDown("lshift")
        or love.keyboard.isDown("rshift")
    self:step()
end

function MovieMap:keypressed(k)
    local keypressed = {
        space = function ()
            self.pause = not self.pause
        end,
        f1 = function()
            self.showoverlay = not self.showoverlay
        end,
        ['.'] = function()
            if self.pause then
                self:step()
            end
        end
    }

    local i = tonumber(k)
    if i then
        self:startMovie(i == 0 and 10 or i)
        return
    end
    if keypressed[k] then keypressed[k]() end
end

function MovieMap:drawOverlay()
    if not self.showoverlay then return end

    local gw, gh = Gfx.getDimensions()
        --self.width * self.tilewidth, self.height * self.tileheight

    local font = Gfx.getFont()
    ---@cast font love.Font
    local fh = font:getHeight()

    Gfx.setColor(0, 1, 0)
    Gfx.printf("Press a number to play", font, 0, 0, gw, "left")

    local movies = self.layers
    local y = fh
    for i = 1, math.min(10, #movies) do
        local s = string.format("%s %d. %s",
            i == self.playingi and '>' or ' ',
            i == 10 and 0 or i, movies[i].name)
        local light = Movie.is(movies[i]) and 1 or .5
        Gfx.setColor(0, light, 0)
        Gfx.printf(s, font, 0, y, gw, "left")
        y = y + fh
    end

    Gfx.setColor(0, 1, 0)
    Gfx.printf(tostring(self.time), font, 0, gh-fh, gw, "left")
    if self.pause then
        Gfx.printf("PAUSE", font, 0, fh, gw, "right")
    end
end

function MovieMap:drawError()
    local gw, gh = Gfx.getDimensions() --self.width, self.height
    local font = Gfx.getFont()
    ---@cast font love.Font
    if self.movieerror then
        Gfx.setColor(0, 0, 0, .75)
        Gfx.rectangle("fill", 8, 8, gw-16, gh-16)
        Gfx.setColor(1, 0, 0)
        Gfx.printf(self.movieerror, font, 8, 16, gw-8, "left")
    end
end

function MovieMap:draw()
    Map.draw(self)
    self:drawOverlay()
    self:drawError()
end

return MovieMap