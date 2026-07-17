local has_ffi, ffi = pcall(require, "ffi")
if not has_ffi then
    return false
end

local lib = require "VGMPlayer.ffi"
if not lib then
    return false
end

---@class VGMPlayer
---@field thread love.Thread
---@field threadinput love.Channel
local VGMPlayer = {}
VGMPlayer.__index = VGMPlayer

function VGMPlayer:getType()
    return "stream"
end

function VGMPlayer:play()
    self:stop()
    self.thread:start(self.filedata, self.buffersamples, self.rate, self.threadinput, self.volume)
end

function VGMPlayer:unpause()
    self.threadinput:push("play")
end

function VGMPlayer:pause()
    self.threadinput:push("pause")
end

function VGMPlayer:stop()
    if self.thread:isRunning() then
        self.threadinput:push("stop")
        self.thread:wait()
    end
end

function VGMPlayer:setLooping(_)
end

function VGMPlayer:setVolume(v)
    self.volume = v
    if self.thread:isRunning() then
        self.threadinput:push("volume")
        self.threadinput:push(v)
    end
end

function VGMPlayer:getVolume()
    return self.volume
end

function VGMPlayer:fade(seconds)
    self.threadinput:push("fade")
    self.threadinput:push(seconds or 1)
end

function VGMPlayer.new(filename, buffersamples, rate)
    -- local filetype = lib.gme_identify_extension(filename)
    -- if filetype == nil then
    --     return nil, filename.." is not an emulated music file"
    -- end
    local data, error = love.filesystem.newFileData(filename)
    if not data then
        return nil, error
    end
    if data:getExtension() == "vgz" then
        local str = love.data.decompress(data, "gzip")
        data = love.filesystem.newFileData(str, "decompressedmusic")
    end

    local player = {
        volume = 1,
        filedata = data,
        buffersamples = buffersamples or 2048,
        rate = rate or 44100,
        thread = love.thread.newThread([[
            require("VGMPlayer.PlayThread")(...)
        ]]),
        threadinput = love.thread.newChannel()
    }
    setmetatable(player, VGMPlayer)
    return player
end

return VGMPlayer
