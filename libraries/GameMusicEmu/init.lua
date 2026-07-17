local has_ffi, ffi = pcall(require, "ffi")
if not has_ffi then
    return false
end

local lib = require "GameMusicEmu.ffi"
if not lib then
    return false
end

---@class GameMusicEmu
---@field thread love.Thread
---@field threadinput love.Channel
local GameMusicEmu = {}
GameMusicEmu.__index = GameMusicEmu

function GameMusicEmu:getType()
    return "stream"
end

function GameMusicEmu:play(track)
    self:stop()
    self.thread:start(self.filedata, track or 0, self.buffersamples, self.rate, self.threadinput, self.volume)
end

function GameMusicEmu:getTrackInfo(track)
--     local trackinfo = ffi.new("gme_info_t*[1]")
--     lib.gme_track_info(self.musicemu, trackinfo, track);
--     return trackinfo[0]
end

function GameMusicEmu:unpause()
    self.threadinput:push("play")
end

function GameMusicEmu:pause()
    self.threadinput:push("pause")
end

function GameMusicEmu:stop()
    if self.thread:isRunning() then
        self.threadinput:push("stop")
        self.thread:wait()
    end
end

function GameMusicEmu:setLooping(_)
end

function GameMusicEmu:setVolume(v)
    self.volume = v
    if self.thread:isRunning() then
        self.threadinput:push("volume")
        self.threadinput:push(v)
    end
end

function GameMusicEmu:getVolume()
    return self.volume
end

function GameMusicEmu:fade()
    self.threadinput:push("fade")
end

function GameMusicEmu.isSupported(filename)
    return lib.gme_identify_extension(filename) ~= nil
end

function GameMusicEmu.new(filename, buffersamples, rate)
    local filetype = lib.gme_identify_extension(filename)
    if filetype == nil then
        return nil, filename.." is not an emulated music file"
    end
    local data, error = love.filesystem.newFileData(filename)
    if not data then
        return nil, error
    end
    if data:getExtension() == "vgz" then
        local str = love.data.decompress(data, "gzip")
        data = love.filesystem.newFileData(str, "decompressedmusic")
    end

    local musicemu = {
        volume = 1,
        filedata = data,
        buffersamples = buffersamples or 2048,
        rate = rate or 44100,
        thread = love.thread.newThread([[
            require("GameMusicEmu.PlayThread")(...)
        ]]),
        threadinput = love.thread.newChannel()
    }
    setmetatable(musicemu, GameMusicEmu)
    return musicemu
end

return GameMusicEmu
