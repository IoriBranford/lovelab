local FS = love.filesystem
local GX = love.graphics

FS.setRequirePath(table.concat({
    FS.getRequirePath(),
    "source/?.lua",
    "source/?/init.lua",
    "libraries/?.lua",
    "libraries/?/init.lua",
}, ';'))

require "love.eventconnect"
local fixedupdate = require "fixedupdate"

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
function love.load(args)
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
    love.reload()
end

local A = 0
local T = 0

local Player = {
    x = 0, y = 0,
    vx = 0,
    vy = 0,
    gamepadaxisself = function(self, gp, ax, val)
        if ax == "leftx" then
            self.vx = val*8
        elseif ax == "lefty" then
            self.vy = val*8
        end
    end,
    updateself = function(self)
        local x = self.x + self.vx
        local y = self.y + self.vy
        local gw, gh = GX.getDimensions()
        self.x = math.max(0, math.min(x, gw))
        self.y = math.max(0, math.min(y, gh))
    end,
    drawself = function(self, t)
        local x = self.x + self.vx*t
        local y = self.y + self.vy*t
        GX.circle("fill", x, y, 30)
    end
}

function love.reload()
    A = 0
    love.event.newEvents("fixedupdate", "fixeddraw", "gamepadaxisself", "updateself", "drawself")

    local gw, gh = GX.getDimensions()

    Player.x = gw / 2
    Player.y = gh / 2
    love.event.connectAll(Player)
end

function love.gamepadaxis(...)
    love.event.sendSelves("gamepadaxisself", ...)
end

function love.keypressed(k)
    if k == 'f2' then
        love.event.reset()
    end
end

---@diagnostic disable-next-line: duplicate-set-field
love.update = function(dt)
    T = fixedupdate(60, T, dt, function ()
        love.event.send("fixedupdate")
        love.event.sendSelves("updateself")
    end)
end

---@diagnostic disable-next-line: duplicate-set-field
love.draw = function()
    local ghw = GX.getWidth() / 2
    local ghh = GX.getHeight() / 2
    local fhh = GX.getFont():getHeight() / 2
    GX.printf("love.eventconnect", ghw, ghh, 2 * ghh, "center", A, 1, 1, ghh, fhh)
    love.event.sendSelves("drawself", T)
end
