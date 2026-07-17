return function(filedata, track, buffersamples, rate, input, volume)
    local has_ffi, ffi = pcall(require, "ffi")
    if not has_ffi then
        return
    end
    local gme = require "GameMusicEmu.ffi"
    if not gme then
        return
    end

    local gme_play = gme.gme_play

    love.sound = require "love.sound"
    love.audio = require "love.audio"
    love.timer = require "love.timer"

    local sleep = love.timer.sleep

    local sounddata = love.sound.newSoundData(buffersamples/2, rate)
    local pointer = sounddata:getFFIPointer()
    local source = love.audio.newQueueableSource(rate, 16, 2)
    source:setVolume(volume or 1)

    local musicemu = ffi.new("Music_Emu*[1]")
    gme.gme_open_data(filedata:getFFIPointer(), filedata:getSize(), musicemu, rate)
    musicemu = musicemu[0]

    local function queueBuffers(n)
        n = math.min(n, source:getFreeBufferCount())
        for _ = 1, n do
            gme_play(musicemu, buffersamples, pointer)
            source:queue(sounddata)
        end
    end

    gme.gme_start_track(musicemu, track)
    queueBuffers(source:getFreeBufferCount())
    source:play()

    local paused = false
    while true do
        local cmd = input:pop()
        if cmd == "play" then
            paused = false
        elseif cmd == "pause" then
            paused = true
        elseif cmd == "stop" then
            break
        elseif cmd == "volume" then
            volume = input:demand()
            source:setVolume(volume)
        elseif cmd == "fade" then
            gme.gme_set_fade(musicemu, gme.gme_tell(musicemu))
        end

        queueBuffers(1)
        if paused then
            source:pause()
        else
            source:play()
        end
        sleep(0.001953125)
    end

    source:stop()
end