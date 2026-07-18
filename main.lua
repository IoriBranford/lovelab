local FS = love.filesystem
local GX = love.graphics

FS.setRequirePath(table.concat({
    FS.getRequirePath(),
    "source/?.lua",
    "source/?/init.lua",
    "libraries/?.lua",
    "libraries/?/init.lua",
}, ';'))

local lovewich = require "lovewich"

local fixed_timestep = require "fixed_timestep"

local cli = FS.getIdentity()
if not love.filesystem.isFused() then
    cli = cli .. [[
        <game> (string)         Game assets location
    ]]
end
cli = cli..[[
    --console               Output to a console window
    --version               Print LOVE version
    --fused                 Force running in fused mode
    -d,--debug                 Debug with tomblind.local-lua-debugger-vscode
    --profile               Profile code performance
    --os (optional string)  Fake a certain OS for testing
    <files...> (string)   One or more LOVE programs to run
]]

---@diagnostic disable-next-line: duplicate-set-field
function love.run()
    local args = require "pl.lapp"(cli)

	if args.debug then
		require("lldebugger").start()
	end

    if args.profile then
        jit.off()
        local profile = require("jit.p")
        local filename = love.filesystem.getSaveDirectory() .. "/" .. os.date("profile_%Y-%m-%d_%H-%M-%S") .. ".txt"
        profile.start("Fli1", filename)
    end

    local LW = lovewich.new()

    GX.setNewFont(16)

    local files = args.files
    local function loadf(i, file)
        local ft, err = LW:pushfile(file)
        if ft then return end

        err = string.format("%d. %s: %s", i, file, err)
        print(err)
        LW[#LW+1] = {
            draw = function()
                local mrg = 10
                local w = GX.getWidth()
                local font = GX.getFont()
                local fh = font:getHeight()
                local x, y = mrg, fh*i
                w = w - 2*mrg
                GX.printf(err, x, y, w, "left")
            end
        }
    end
    for i, file in ipairs(files) do
        loadf(i, file)
    end


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
				LW:inevent(name,a,b,c,d,e,f)
			end
		end

		if love.timer then dt = love.timer.step() end

        local t = fixedtimestep(dt, LW.outevent, LW, "fixedupdate")
        LW:outevent("animate", dt)

		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())

            LW:outevent("draw", t)

			love.graphics.present()
		end

		if love.timer then love.timer.sleep(0.001) end
	end
end