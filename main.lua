local dispatch = require "dispatch"
local FS = love.filesystem
local GX = love.graphics

FS.setRequirePath(table.concat({
    FS.getRequirePath(),
    "source/?.lua",
    "source/?/init.lua",
    "libraries/?.lua",
    "libraries/?/init.lua",
}, ';'))

local function drawLoadError(i, err)
    local mrg = 10
    local w = GX.getWidth()
    local font = GX.getFont()
    local fh = font:getHeight()
    local x, y = mrg, fh * i
    w = w - 2 * mrg
    GX.printf(err, x, y, w, "left")
end

---@diagnostic disable-next-line: duplicate-set-field
function love.load()
    local cli = FS.getIdentity()
    if not love.filesystem.isFused() then
        cli = cli .. [[
            <game> (string)         Game assets location
        ]]
    end
    cli = cli .. [[
        --console               Output to a console window
        --version               Print LOVE version
        --fused                 Force running in fused mode
        -d,--debug              Debug with tomblind.local-lua-debugger-vscode
        --profile               Profile code performance
        --os (optional string)  Fake a certain OS for testing
        <files...> (optional string)   One or more LOVE programs to run
    ]]

    local args = require "pl.lapp" (cli)

    if args.debug then
        require("lldebugger").start()
    end

    if args.profile then
        jit.off()
        local profile = require("jit.p")
        local filename = love.filesystem.getSaveDirectory() .. "/" .. os.date("profile_%Y-%m-%d_%H-%M-%S") .. ".txt"
        profile.start("Fli1", filename)
    end

    -- local files = args.files
    -- local function loadf(i, file)
    --     local ft, err = LW:pushfile(file)
    --     if ft then return end

    --     err = string.format("%d. %s: %s", i, file, err)
    --     print(err)
    --     LW[#LW+1] = {
    --         draw = function() drawLoadError(i, err) end
    --     }
    -- end

    -- local i1 = FS.isFused() and 1 or 2
    -- for i = i1, #files do
    --     loadf(i, files[i])
    -- end

    -- if #Dispatch.events.draw <= 0 then
    --     Dispatch:allsub({
    --         draw = function()
    --             drawLoadError(1, "No code files")
    --         end
    --     })
    -- end
    GX.setNewFont(64)
end

local a = 0

---@diagnostic disable-next-line: duplicate-set-field
love.update = function (dt)
    a = a + dt
end

---@diagnostic disable-next-line: duplicate-set-field
love.draw = function()
    local ghw = GX.getWidth()/2
    local ghh = GX.getHeight()/2
    local fhh = GX.getFont():getHeight()/2
    GX.printf("love.eventconnect", ghw, ghh, 2*ghh, "center", a, 1, 1, ghh, fhh)
end

local Dispatch = dispatch.new("audiodisconnected", "directorydropped", "displayrotated", "draw", "dropbegan",
    "dropcompleted", "dropmoved", "exposed", "filedropped", "focus", "gamepadaxis", "gamepadpressed", "gamepadreleased",
    "joystickadded", "joystickaxis", "joystickhat", "joystickpressed", "joystickreleased", "joystickremoved",
    "joysticksensorupdated", "keypressed", "keyreleased", "load", "localechanged", "lowmemory", "mousefocus",
    "mousemoved", "mousepressed", "mousereleased", "occluded", "quit", "resize", "sensorupdated", "textedited",
    "textinput", "threaderror", "touchmoved", "touchpressed", "touchreleased", "update", "visible", "wheelmoved")

---@diagnostic disable-next-line: duplicate-set-field
function love.run()
    Dispatch:allsub(love)
    Dispatch:send("load", love.arg.parseGameArguments(arg), arg)

    -- We don't want the first frame's dt to include time taken by love.load.
    if love.timer then love.timer.step() end

    local dt = 0

    -- Main loop time.
    return function()
        -- Process events.
        if love.event then
            love.event.pump()
            for name, a, b, c, d, e, f in love.event.poll() do
                if name == "quit" then
                    if not love.quit or not love.quit() then
                        return "quit", a or 0
                    end
                end
                Dispatch:send(name, a, b, c, d, e, f)
            end
        end

        -- Update dt, as we'll be passing it to update
        if love.timer then dt = love.timer.step() end

        -- Call update and draw
        Dispatch:send("update", dt) -- will pass 0 if love.timer is disabled

        if love.graphics and love.graphics.isActive() then
            love.graphics.origin()
            love.graphics.clear(love.graphics.getBackgroundColor())

            Dispatch:send("draw")

            love.graphics.present()
        end

        if love.timer then love.timer.sleep(0.001) end
    end
end