--- to upscale pixel games nicely
local PixelScaler = {}
local GX = love.graphics
local min = math.min

local Width, Height
local WC ---@type love.Canvas
local SC ---@type love.Canvas
local WRes, SRes = 1, 1
local WScale, SScale = 1, 1

---@param c love.Canvas?
local function resizeCanvas(c, w, h, s, filter)
    local cw2, ch2 = w*s, h*s

    if c then
        local cw1, ch1 = c:getDimensions()
        if cw1 == cw2 and ch1 == ch2 then
            if filter then
                c:setFilter(filter)
            end
            return c
        end
    end

    c = GX.newCanvas(cw2, ch2)
    c:setFilter(filter)
end

function PixelScaler.load(width, height, worldres, upscale)
    Width, Height = width, height
    love.graphics.setDefaultFilter("nearest", "nearest")
    local w,h = width, height
    WC = resizeCanvas(nil, w, h, worldres, "nearest")
    SC = resizeCanvas(nil, w, h, upscale, "linear")
    WRes, SRes = worldres, upscale
    WScale = SRes/WRes
end

function PixelScaler.resize(neww, newh)
    local gw, gh = GX.getDimensions()
    local sw, sh = SC:getDimensions()
    SScale = min(gw/sw, gh/sh)
end

function PixelScaler.draw_cb()
    GX.setCanvas(WC)
    coroutine.yield()
    GX.setCanvas(SC)
    GX.draw(WC, 0, 0, 0, WScale)
    GX.setCanvas()
    GX.draw(SC, 0, 0, 0, SScale)
end

local configset = {}

function PixelScaler.configset(k, v)
    if configset[k] then configset[k](v) end
end

function configset.resolution(wres)
    WC = resizeCanvas(WC, Width, Height, wres)
    WRes = wres
    WScale = SRes/WRes
end

function configset.upscale(res)
    SC = resizeCanvas(SC, Width, Height, res)
end

function configset.linearfilter(filter)
    if filter == "WORLD" or filter == "BOTH" then
        WC:setFilter("linear")
    else
        WC:setFilter("nearest")
    end
    if filter == "SCREEN" or filter == "BOTH" then
        SC:setFilter("linear")
    else
        SC:setFilter("nearest")
    end
end

return PixelScaler