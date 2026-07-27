love.debug = {}

local lldebugger

function love.debug.load(args)
	local debug, breakImmediately
	local loadarg = setmetatable({
		["--debug"] = function() debug = true end,
        ["--startbreak"] = function() breakImmediately = true end
	}, {
        __index = function (arg) print("Not a debug arg", arg) end
    })
	for _, arg in ipairs(args) do
		loadarg[arg](arg)
	end
    if not debug then return end
    lldebugger = require "lldebugger"
	lldebugger.start(breakImmediately)
end
