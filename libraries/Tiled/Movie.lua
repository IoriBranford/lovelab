local LayerGroup = require "Tiled.LayerGroup"

---@class Movie:LayerGroup
---@field thread thread
---@field func function
---@field script string
local Movie = class(LayerGroup)
--MovieScene.runphase = "Dragontail.MoviePhase"

function Movie:started()
    return self.thread ~= nil
end

function Movie:start(arg, ...)
    local script = self.script
    local _, scriptf = assert(pcall(require, script))
    self.func = scriptf
    self.thread = coroutine.create(self.func)
    if arg ~= nil then
        self:play(arg, ...)
    end
    return self.thread
end

function Movie:play(...)
    local thread = self.thread or self:start()
    if coroutine.status(thread) == "dead" then return "dead" end
    return coroutine.resume(thread, self, ...)
end

function Movie:ended()
    return self.thread and coroutine.status(self.thread) == "dead"
end

return Movie