return function(filedata, buffersamples, rate, input, volume)
    local has_ffi, ffi = pcall(require, "ffi")
    if not has_ffi then
        return
    end
    local libvgmplayer = require "VGMPlayer.ffi"
    if not libvgmplayer then
        return
    end

    local render = libvgmplayer.PlayerC_Render

    love.sound = require "love.sound"
    love.audio = require "love.audio"
    love.timer = require "love.timer"

    local sleep = love.timer.sleep

    local sounddata = love.sound.newSoundData(buffersamples, rate)
    local soundbytes = sounddata:getSize()
    local pointer = sounddata:getFFIPointer()
    local source = love.audio.newQueueableSource(rate, 16, 2)
    source:setVolume(volume or 1)

    local player = libvgmplayer.PlayerC_NewVGM()
    libvgmplayer.PlayerC_SetOutputSettings(player, rate, 2, 16, buffersamples)
    libvgmplayer.PlayerC_LoadMemory(player, filedata:getFFIPointer(), filedata:getSize())

    local function queueBuffers(n)
        n = math.min(n, source:getFreeBufferCount())
        for _ = 1, n do
            render(player, soundbytes, pointer)
            source:queue(sounddata)
        end
    end

    libvgmplayer.PlayerC_Start(player)
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
            local seconds = input:demand()
            libvgmplayer.PlayerC_SetFadeSeconds(player, seconds)
            libvgmplayer.PlayerC_FadeOut(player)
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
    libvgmplayer.PlayerC_Stop(player)
end