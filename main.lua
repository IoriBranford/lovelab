require "love.debug"
require "love.eventconnect"

local GX = love.graphics

---@diagnostic disable-next-line: duplicate-set-field
function love.load(args)
    love.debug.load(args)
	GX.setNewFont(64)

	local a = 0
	love.event.connectAll({
		update = function (dt)
			a = a + dt
		end,
		draw = function()
			local ghw = GX.getWidth()/2
			local ghh = GX.getHeight()/2
			local fhh = GX.getFont():getHeight()/2
			GX.printf("love.eventconnect", ghw, ghh, 2*ghh, "center", a, 1, 1, ghh, fhh)
		end
	})
end

---@diagnostic disable-next-line: duplicate-set-field
function love.quit()

end
-- Callback function triggered when the game is closed.

---@diagnostic disable-next-line: duplicate-set-field
function love.run()
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end

	local dt = 0

	-- Main loop time.
	return function()
		-- Process events.
		if love.event then
            local exit, exitcode = love.event.update()
            if exit then
                return exitcode or 0
            end
		end

		-- Update dt, as we'll be passing it to update
		if love.timer then dt = love.timer.step() end

		-- Call update and draw
		love.event.send("update", dt) -- will pass 0 if love.timer is disabled

		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())

			love.event.send("draw")

			love.graphics.present()
		end

		if love.timer then love.timer.sleep(0.001) end
	end
end