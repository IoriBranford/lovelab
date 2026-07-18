---@class Config:BaseConfig
local Config = {}
local pl_pretty = require "pl.pretty"
local Platform  = require "System.Platform"
local ControllerInputNames = require "ControllerInputNames"
local Window               = require "System.Window"

local filename = "config.lua"

local config
local defaultconfig

function Config.reset()
	---@class BaseConfig
	---@field [string] number|boolean|string|table
	config = {
        debug = false,
        fullscreen = false,
		maximize = true,
        fullscreenexclusive = false,
        fullscreendevice = 1,
        vsync = false,
        usedpiscale = false,
        musicvolume = 0.5,
        soundvolume = 0.5,
        resizable = true,
        drawstats = false,
		drawgraphicstats = false,
        rotation = 0,
		variableupdate = false,
		fixedupdaterate = 60,
	}
	if defaultconfig then
		for k,v in pairs(defaultconfig) do
			config[k] = v
		end
	end
end
Config.reset()

Config.cli = [[
    --fullscreen            	Start in fullscreen mode
    --borderless             	Non-exclusive fullscreen
    --exclusive             	Exclusive fullscreen
    --display (optional number)	Number of the display to use in fullscreen
    --windowed              	Start in windowed mode
    --drawstats             	Draw basic performance stats
    --drawgraphicstats			Draw detailed graphics performance stats
]]

function Config.clamp(key, min, max)
	local value = config[key]
	if type(value) == "number" then
		config[key] = math.max(min, math.min(value, max))
	end
end

function Config.load(defaultcfg)
	defaultconfig = defaultcfg
	Config.reset()
	if love.filesystem.getInfo(filename) then
		local fileconfig = love.filesystem.load(filename)()
		local fileversion = fileconfig._version or 0
		if fileversion == defaultconfig._version then
			local function fill(t1, t2)
				for k,v2 in pairs(t2) do
					local v1 = t1[k]
					if type(v1) == "table"
					and type(v2) == "table" then
						fill(v1, v2)
					else
						t1[k] = v2
					end
				end
			end
			fill(Config, fileconfig)
		else
			local oldfilename = filename.."."..fileversion
			if Platform.supports("saveconfig") then
				local configtext = "return "..pl_pretty.write(fileconfig)
				love.filesystem.write(oldfilename, configtext)
			end
		end
	end
	Config.clamp("fullscreendevice", 1, love.window.getDisplayCount())
end

function Config.parseArgs(args)
	if args.exclusive then
    	Config.fullscreenexclusive = true
	end
	if args.borderless then
    	Config.fullscreenexclusive = false
	end
	if args.display then
	    Config.fullscreendevice = math.floor(args.display)
		Config.clamp("fullscreendevice", 1, love.window.getDisplayCount())
	end
    if args.rotation ~= -1 then
        Config.rotation = args.rotation
    end
    if args.fullscreen then
        Config.fullscreen = true
    elseif args.windowed then
        Config.fullscreen = false
    end

    Config.drawstats = args.drawstats
    Config.drawgraphicstats = args.drawgraphicstats
end

function Config.save()
	if not Platform.supports("saveconfig") then
		return
	end
	local configtext = "return "..pl_pretty.write(config)
	love.filesystem.write(filename, configtext)
end

local function getConfigValueOrInputName(key)
	local value = config[key]
	local inputnames = ControllerInputNames[config.joy_namingscheme or "XBOX"]
	local inputname = inputnames[value] or inputnames[key]
	return inputname or value
end

function Config.gsub(s)
	return s:gsub("${([_%w]+)}", getConfigValueOrInputName)
end

local apply = {
	fullscreen = function (fs)
		love.window.setFullscreen(fs,
			Config.fullscreenexclusive and "exclusive"
				or "desktop")
	end,
	fullscreendevice = Window.setMonitor,
	fullscreenexclusive = function (exclusive)
		love.window.setFullscreen(Config.fullscreen,
			exclusive and "exclusive" or "desktop")
	end,
	vsync = function(v)
		love.window.setVSync(v and 1 or 0)
	end,
	rotation = function()
    	local _,_, flags = love.window.getMode()
		local neww, newh = Window.calcDisplaySize(flags.minwidth, flags.minheight)
		Window.resize(neww, newh)
	end,
	musicvolume = function(volume)
		local Audio                = require "System.Audio"
		Audio.setMusicVolume(volume)
	end,
}

function Config.apply(key)
	if apply[key] then
		local value = config[key]
		local newvalue = apply[key](value)
		config[key] = newvalue ~= nil and newvalue or value
	end
end

function Config.setApply(key, action)
	apply[key] = action
	return config[key]
end

setmetatable(Config, {
	__index = function(_, k)
		return config[k]
	end,
	__newindex = function(_, k, v)
		if config[k] == nil then
			print("W: Ignoring unknown config variable "..k)
		else
			config[k] = v
		end
	end
})

return Config