local FS = love.filesystem
local GX = love.graphics

FS.setRequirePath(table.concat({
    FS.getRequirePath(),
    -- "source/?.lua",
    -- "source/?/init.lua",
    "libraries/?.lua",
    "libraries/?/init.lua",
}, ';'))

local mapstack = require "mapstack"

local fixed_timestep = require "fixed_timestep"

---@diagnostic disable-next-line: duplicate-set-field
function love.run()
	local args = love.arg.parseGameArguments(arg)

    local debugger
    for _, a in ipairs(args) do
        if a == "--debug" then
            debugger = require("lldebugger")
        else
            local map, err = mapstack.load(a)
            if map then
                mapstack.push(map)
            else
                print(err)
            end
        end
    end
    if debugger then debugger.start() end

	-- We don't want the first frame's dt to include
    -- time taken by love.load.
	if love.timer then love.timer.step() end

	local dt = 0
    local fixedtimestep = fixed_timestep(60)

	return function()
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a or 0
					end
				end
				mapstack.event(name,a,b,c,d,e,f)
			end
		end

		if love.timer then dt = love.timer.step() end

        local t = fixedtimestep(dt, mapstack.event, "fixedupdate")
        mapstack.event("animate", dt)

		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())

            if mapstack.empty() then
                local gw, gh = GX.getDimensions()
                GX.printf("No maps", 0, 0, gw, "center")
            else
                mapstack.event("draw", t)
            end

			love.graphics.present()
		end

		if love.timer then love.timer.sleep(0.001) end
	end
end