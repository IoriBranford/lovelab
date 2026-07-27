local dispatch = require "dispatch"
local FS = love.filesystem

FS.setRequirePath(table.concat({
    FS.getRequirePath(),
    "source/?.lua",
    "source/?/init.lua",
    "libraries/?.lua",
    "libraries/?/init.lua",
}, ';'))

---@diagnostic disable-next-line: duplicate-set-field
function love.run()
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
        -d,--debug              Debug with tomblind.local-lua-debugger-vscode
        --profile               Profile code performance
        --os (optional string)  Fake a certain OS for testing
        <files...> (optional string)   One or more LOVE programs to run
    ]]

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

    local GX = love.graphics

    local function drawLoadError(i, err)
        local mrg = 10
        local w = GX.getWidth()
        local font = GX.getFont()
        local fh = font:getHeight()
        local x, y = mrg, fh*i
        w = w - 2*mrg
        GX.printf(err, x, y, w, "left")
    end

    local dsph = dispatch.new(
        "load",
        "update",
        "draw",
        "quit"
    )

    local files = args.files
    local function loadf(i, file)
        -- local ft, err = LW:pushfile(file)
        -- if ft then return end

        -- err = string.format("%d. %s: %s", i, file, err)
        -- print(err)
        -- LW[#LW+1] = {
        --     draw = function() drawLoadError(i, err) end
        -- }
    end

    local i1 = FS.isFused() and 1 or 2
    for i = i1, #files do
        loadf(i, files[i])
    end

    if #dsph.events.draw <= 0 then
        dsph:allsub({
            draw = function()
                drawLoadError(1, "No code files")
            end
        })
    end

    GX.setNewFont(16)

    -- We don't want the first frame's dt to include time taken by love.load.
    if love.timer then love.timer.step() end

    local dt = 0

    -- Main loop time.
    return function()
        -- Process events.
        if love.event then
            love.event.pump()
            for name, a,b,c,d,e,f in love.event.poll() do
                if name == "quit" then
                    if not love.quit or not love.quit() then
                        return "quit", a or 0
                    end
                end
                dsph:send(name, a, b, c, d, e, f)
            end
        end

        -- Update dt, as we'll be passing it to update
        if love.timer then dt = love.timer.step() end

        -- Call update and draw
        dsph:send("update", dt) -- will pass 0 if love.timer is disabled

        if love.graphics and love.graphics.isActive() then
            love.graphics.origin()
            love.graphics.clear(love.graphics.getBackgroundColor())

            dsph:send("draw")

            love.graphics.present()
        end

        if love.timer then love.timer.sleep(0.001) end
    end
end