local settings = require "src.core.settings"

local audio = {
    music = {},
    sfx = {},
    currentTrack = nil,
    currentMusic = nil
}

local function loadSource(path, mode)
    local ok, src = pcall(love.audio.newSource, path, mode)
    if ok then
        return src
    end
    print("Audio failed to load: " .. path .. " (" .. tostring(src) .. ")")
    return nil
end

local function makePool(path, size)
    local template = loadSource(path, "static")
    if not template then
        return {items = {}, next = 1}
    end
    local items = {template}
    for i = 2, size do
        items[i] = template:clone()
    end
    return {items = items, next = 1}
end

function audio.load()
    audio.music.menu = loadSource("assets/Main_Theme.mp3", "stream")
    audio.music.battle = loadSource("assets/Battle_Theme.mp3", "stream")
    if audio.music.menu then
        audio.music.menu:setLooping(true)
    end
    if audio.music.battle then
        audio.music.battle:setLooping(true)
    end

    audio.sfx.slash = makePool("assets/slash.wav", 20)
    audio.sfx.shoot = makePool("assets/shoot.wav", 20)
    audio.sfx.freeze = makePool("assets/freeze.wav", 20)
    audio.sfx.chest = makePool("assets/chest_open.wav", 12)
end

function audio.setWorld(frustum, camera)
    audio.frustum = frustum
    audio.camera = camera
end

function audio.applyVolumes()
    local master = settings.masterVolume or 1
    local musicVol = (settings.music and (settings.musicVolume or 1) or 0) * master
    if audio.currentMusic then
        audio.currentMusic:setVolume(musicVol)
        if settings.music and musicVol > 0 then
            if not audio.currentMusic:isPlaying() then
                audio.currentMusic:play()
            end
        else
            audio.currentMusic:pause()
        end
    end
end

function audio.playMusic(track)
    local src = audio.music[track]
    if audio.currentTrack == track and audio.currentMusic == src then
        audio.applyVolumes()
        return
    end
    if audio.currentMusic then
        audio.currentMusic:stop()
    end
    audio.currentTrack = track
    audio.currentMusic = src
    audio.applyVolumes()
    if src and settings.music and (settings.masterVolume or 1) > 0 and (settings.musicVolume or 1) > 0 then
        src:play()
    end
end

function audio.playSfx(name, volumeMul)
    if not settings.sfx then
        return
    end
    local bank = audio.sfx[name]
    if not bank or #bank.items == 0 then
        return
    end
    local src = bank.items[bank.next]
    bank.next = bank.next + 1
    if bank.next > #bank.items then
        bank.next = 1
    end
    local volume = (settings.sfxVolume or 1) * (settings.masterVolume or 1) * (volumeMul or 1)
    src:stop()
    src:setPitch(0.94 + math.random() * 0.12)
    src:setVolume(math.max(0, math.min(1, volume)))
    src:play()
end

function audio.playWorld(name, x, y, frustum, camera, volumeMul)
    if not settings.sfx then
        return
    end
    frustum = frustum or audio.frustum
    camera = camera or audio.camera
    local volume = volumeMul or 1
    if frustum and camera then
        local sw, sh = love.graphics.getDimensions()
        if not frustum:isAudible(x, y, camera, sw, sh, 400) then
            return
        end
        local scale = math.max(camera.scale, 0.25)
        volume = volume * math.max(0.55, math.min(1.0, 0.95 / scale))
    end
    audio.playSfx(name, volume)
end

return audio
