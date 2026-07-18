local Config
local Window = {}

local basewidth, baseheight

function Window.init(width, height)
    Config = require "System.Config"
    basewidth = width
    baseheight = height
    Window.refresh()
end

function Window.refresh()
    Window.initDisplayMode(basewidth, baseheight)
end

function Window.isPortraitRotation()
	local rotation = math.rad(Config.rotation)
	return math.abs(math.sin(rotation)) > math.sqrt(2)/2
end

function Window.isPortraitDimensions()
	local w, h, flags = love.window.getMode()
	return w < h
end

function Window.isVertical()
    local portraitrotation = Window.isPortraitRotation()
    local portraitdimensions = Window.isPortraitDimensions()
    return portraitrotation and not portraitdimensions
    	or portraitdimensions and not portraitrotation
end

function Window.calcDisplaySize(basew, baseh)
	local deskwidth, deskheight = love.window.getDesktopDimensions(Config.fullscreendevice)
	if Config.fullscreen then
		return deskwidth, deskheight
	end

	if Window.isPortraitRotation() then
		basew, baseh = baseh, basew
	end

	local maxscale = math.min(deskwidth/basew, deskheight/baseh)
	maxscale = math.floor(maxscale)
	return basew*maxscale, baseh*maxscale
end

function Window.initDisplayMode(basew, baseh)
	local w, h = Window.calcDisplaySize(basew, baseh)

	-- Config.clamp("fullscreendevice", 1, love.window.getDisplayCount())
	local flags = {
		fullscreen = Config.fullscreen,
		usedpiscale = Config.usedpiscale,
		vsync = Config.vsync,
		resizable = Config.resizable,
		minwidth = basew,
		minheight = baseh,
        fullscreentype = Config.exclusive and "exclusive" or "desktop",
        display = Config.fullscreendevice
	}
	love.window.setMode(w, h, flags)
end

function Window.updateDisplayMode(flags)
	local w, h, currentflags = love.window.getMode()
	w, h = Window.calcDisplaySize(currentflags.minwidth, currentflags.minheight)
	love.window.updateMode(w, h, flags)
end

function Window.setMonitor(monitor)
    monitor = math.max(1, math.min(monitor, love.window.getDisplayCount()))
    local w, h, flags = love.window.getMode()
    local neww, newh = Config.calcDisplaySize(flags.minwidth, flags.minheight)
    love.window.updateMode(neww, newh, { display = monitor })
    love.event.push("resize", neww, newh)
    return monitor
end

function Window.resize(neww, newh, flags)
    local w, h = love.window.getMode()
    if w ~= neww or h ~= newh then
        love.window.updateMode(neww, newh, flags or {})
    end
    love.event.push("resize", neww, newh)
end

return Window