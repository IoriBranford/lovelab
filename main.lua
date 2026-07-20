local FS = love.filesystem

FS.setRequirePath(table.concat({
    FS.getRequirePath(),
    "source/?.lua",
    "source/?/init.lua",
    "libraries/?.lua",
    "libraries/?/init.lua",
}, ';'))

local lovewich = require "lovewich"
local fixedupdate = require "fixedupdate"

local LW = lovewich.new()

---@diagnostic disable-next-line: duplicate-set-field
function love.load()
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

    local files = args.files
    local function loadf(i, file)
        local ft, err = LW:pushfile(file)
        if ft then return end

        err = string.format("%d. %s: %s", i, file, err)
        print(err)
        LW[#LW+1] = {
            draw = function() drawLoadError(i, err) end
        }
    end

    local i1 = FS.isFused() and 1 or 2
    for i = i1, #files do
        loadf(i, files[i])
    end

    if #LW <= 0 then
        LW[1] = {
            draw = function()
                drawLoadError(1, "No code files")
            end
        }
    end

    GX.setNewFont(16)
end

local T = 0
local FPS = 60

---@diagnostic disable-next-line: duplicate-set-field
function love.update(dt)
    fixedupdate(FPS, T, dt, LW.up, LW, "fixedupdate")
    LW:up("update", dt)
end

---@diagnostic disable-next-line: duplicate-set-field
function love.draw()
    LW:up("draw", T)
end
