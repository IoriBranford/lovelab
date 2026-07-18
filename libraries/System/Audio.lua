local Config = require "System.Config"
local Assets = require "Tiled.Assets"
local Platform     = require "System.Platform"
local VGMPlayer
local GameMusicEmu
if Platform.supports("ffi") then
    VGMPlayer = require "VGMPlayer"
    if not VGMPlayer then
        GameMusicEmu = require "GameMusicEmu"
    end
end

---@module 'Audio'
local Audio = {}

local music ---@type Music?
local musicqueuedelay = 0
local musicqueuepos = 0
local musicqueue = {}---@type (Music|false)[]
local musicfadespeed = 0

local function load_audio(path, mode)
    local ok, source = pcall(love.audio.newSource, path, mode or "static")
    if ok then
        return source
    end
    print(source)
    return false, source
end

local load_vgm = function(path, ...)
    if VGMPlayer then
        return VGMPlayer.new(path, ...)
    end
    if GameMusicEmu and GameMusicEmu.isSupported(path) then
        return GameMusicEmu.new(path, ...)
    end
    return load_audio(path, "stream")
end

Assets.addLoaders {
    vgm = load_vgm,
    vgz = load_vgm,
    mp3 = load_audio,
    ogg = load_audio,
    wav = load_audio,
    it  = load_audio,
    xm  = load_audio,
    s3m = load_audio,
    mod = load_audio,
}

function Audio.stop()
    Audio.stopMusic()
    love.audio.stop()
end

function Audio.play(file)
    local clip = Assets.get(file)
    if clip then
        ---@cast clip love.Source
        clip:stop()
        clip:setVolume(Config.soundvolume)
        clip:play()
    end
    return clip
end

function Audio.newSource(file)
    local clip = Assets.get(file)
    ---@cast clip love.Source
    return clip and clip:clone()
end

function Audio.setMusicVolume(volume)
    if music then
        music:setVolume(volume)
    end
end

function Audio.getMusicVolume()
    if music then
        return music:getVolume()
    end
    return 0
end

function Audio.update(dsecs)
    if musicqueuepos > 0 then
        if not music or not music:isPlaying() then
            musicqueuedelay = math.max(0, musicqueuedelay - dsecs)
            if musicqueuedelay <= 0 then
                Audio.playNextInMusicQueue()
            end
        end
    end

    if music and musicfadespeed > 0 then
        local volume = music:getVolume() - musicfadespeed * dsecs
        if volume <= 0 then
            Audio.stopMusic()
        else
            music:setVolume(volume)
        end
    end
end

function Audio.stopMusic()
    if music then
        music:stop()
    end
    music = nil
    musicfadespeed = 0
    for i = #musicqueue, 1, -1 do
        musicqueue[i] = nil
    end
    musicqueuepos = 0
    musicqueuedelay = 0
end

function Audio.playMusic(file, track, looping)
    Audio.stopMusic()
    local newmusic = Assets.get(file)
    if newmusic then
        ---@cast newmusic Music
        music = newmusic
        music:setVolume(Config.musicvolume)
        music:play(track)
        music:setLooping(looping or false)
    end
    return music
end

function Audio.loadMusicQueue(...)
    local n = select("#", ...)
    local queue = {}
    for i = 1, n do
        local entry = select(i, ...)
        if type(entry) == "string" then
            local newmusic = Assets.get(entry)
            if newmusic then
                ---@cast newmusic Music
                queue[#queue+1] = newmusic
            end
        elseif type(entry) == "number" then
            queue[#queue+1] = entry
        end
    end
    return queue
end

function Audio.playMusicQueue(...)
    Audio.stopMusic()
    if select("#", ...) > 0 then
        musicqueue = Audio.loadMusicQueue(...)
    end
    Audio.playNextInMusicQueue()
    return musicqueue
end

function Audio.playNextInMusicQueue()
    if musicqueuepos >= #musicqueue then return end
    musicqueuepos = musicqueuepos + 1
    local nextmusic = musicqueue[musicqueuepos]
    if not nextmusic then return end

    if type(nextmusic) == "number" then
        musicqueuedelay = nextmusic
        return
    end

    local volume = music and music:getVolume()
        or Config.musicvolume
    nextmusic:setVolume(volume)
    nextmusic:setLooping(musicqueuepos >= #musicqueue)
    nextmusic:play()
    music = nextmusic
    musicqueuedelay = 0
    return musicqueuepos
end

function Audio.isPlayingMusic()
    return music ~= nil
end

function Audio.fadeMusic(time)
    if music then
        time = time or 3
        musicfadespeed = music:getVolume() / time
    end
    return music
end

return Audio
