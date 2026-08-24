local M = {
    vsync = false,
    fullscreen = true,
    showFps = true,
    showHud = true,
    showGrid = true,
    killPopups = true,
    showHints = true,
    edgePan = false,
    cameraSpeed = 1,
    music = true,
    musicVolume = 0.7,
    sfx = true,
    sfxVolume = 0.85,
    masterVolume = 1,
    debug = false,
    reduceFlash = false
}

local SAVE_FILE = "settings.txt"

local KEYS = {
    "vsync", "fullscreen", "showFps", "showHud", "showGrid", "killPopups",
    "showHints", "edgePan", "cameraSpeed", "music", "musicVolume", "sfx",
    "sfxVolume", "masterVolume", "debug", "reduceFlash"
}

local AUDIO_KEYS = {
    music = true,
    musicVolume = true,
    sfx = true,
    sfxVolume = true,
    masterVolume = true
}

local DISPLAY_KEYS = {
    vsync = true,
    fullscreen = true
}

function M.schema()
    return {
        {key = "vsync", type = "toggle", label = "VSync", section = "Display"},
        {key = "fullscreen", type = "toggle", label = "Fullscreen", section = "Display"},
        {key = "showFps", type = "toggle", label = "Show FPS", section = "Display"},
        {key = "showHud", type = "toggle", label = "Show HUD", section = "Display"},
        {key = "showGrid", type = "toggle", label = "Arena Grid", section = "Display"},
        {key = "showHints", type = "toggle", label = "Control Hints", section = "Display"},
        {key = "reduceFlash", type = "toggle", label = "Reduce Flashing", section = "Display"},
        {key = "killPopups", type = "toggle", label = "Kill Popups", section = "Gameplay"},
        {key = "edgePan", type = "toggle", label = "Edge Pan Camera", section = "Gameplay"},
        {key = "cameraSpeed", type = "slider", label = "Camera Speed", min = 0.5, max = 2, step = 0.05, section = "Gameplay"},
        {key = "masterVolume", type = "slider", label = "Master Volume", min = 0, max = 1, step = 0.01, section = "Audio"},
        {key = "music", type = "toggle", label = "Music", section = "Audio"},
        {key = "musicVolume", type = "slider", label = "Music Volume", min = 0, max = 1, step = 0.01, section = "Audio"},
        {key = "sfx", type = "toggle", label = "Sound Effects", section = "Audio"},
        {key = "sfxVolume", type = "slider", label = "SFX Volume", min = 0, max = 1, step = 0.01, section = "Audio"},
        {key = "debug", type = "toggle", label = "Debug Visuals", section = "Advanced"}
    }
end

function M.categories()
    local cats, seen = {}, {}
    local schema = M.schema()
    for i = 1, #schema do
        local name = schema[i].section
        if not seen[name] then
            seen[name] = true
            cats[#cats + 1] = name
        end
    end
    return cats
end

function M.optionsIn(section)
    local list = {}
    local schema = M.schema()
    for i = 1, #schema do
        if schema[i].section == section then
            list[#list + 1] = schema[i]
        end
    end
    return list
end

function M.findOption(key)
    local schema = M.schema()
    for i = 1, #schema do
        if schema[i].key == key then
            return schema[i]
        end
    end
end

local function parseValue(raw)
    if raw == "true" then
        return true
    elseif raw == "false" then
        return false
    end
    local num = tonumber(raw)
    if num then
        return num
    end
    return raw
end

local function snapSlider(option, value)
    local stepped = math.floor(value / option.step + 0.5) * option.step
    if stepped < option.min then
        stepped = option.min
    elseif stepped > option.max then
        stepped = option.max
    end
    return tonumber(string.format("%.4f", stepped))
end

function M.load()
    if not love.filesystem.getInfo(SAVE_FILE) then
        return
    end
    local contents = love.filesystem.read(SAVE_FILE)
    if not contents then
        return
    end
    for line in contents:gmatch("[^\r\n]+") do
        local key, value = line:match("^([%w_]+)=(.*)$")
        if key and value ~= nil then
            for i = 1, #KEYS do
                if KEYS[i] == key then
                    M[key] = parseValue(value)
                    break
                end
            end
        end
    end
end

function M.save()
    local lines = {}
    for i = 1, #KEYS do
        local key = KEYS[i]
        lines[#lines + 1] = key .. "=" .. tostring(M[key])
    end
    love.filesystem.write(SAVE_FILE, table.concat(lines, "\n"))
end

function M.applyDisplay()
    if love.window.setVSync then
        love.window.setVSync(M.vsync and 1 or 0)
    end
    if love.window.getFullscreen then
        local isFull = love.window.getFullscreen()
        if isFull ~= M.fullscreen then
            love.window.setFullscreen(M.fullscreen)
        end
    end
end

function M.applyAudio()
    local ok, audio = pcall(require, "src.audio")
    if ok and audio.applyVolumes then
        audio.applyVolumes()
    end
end

function M.apply()
    M.applyDisplay()
    M.applyAudio()
end

function M.applyKey(key)
    if DISPLAY_KEYS[key] then
        M.applyDisplay()
    elseif AUDIO_KEYS[key] then
        M.applyAudio()
    end
end

function M.set(key, value, persist)
    if M[key] ~= value then
        M[key] = value
        M.applyKey(key)
    end
    if persist ~= false then
        M.save()
    end
    return M[key]
end

function M.setSliderT(key, t, persist)
    local option = M.findOption(key)
    if not option or option.type ~= "slider" then
        return M[key]
    end
    t = math.max(0, math.min(1, t))
    local value = snapSlider(option, option.min + t * (option.max - option.min))
    return M.set(key, value, persist)
end

function M.toggle(key)
    return M.set(key, not M[key], true)
end

function M.nudge(key, dir)
    local option = M.findOption(key)
    if not option or option.type ~= "slider" then
        return M[key]
    end
    return M.set(key, snapSlider(option, M[key] + dir * option.step), true)
end

function M.toggleVSync()
    return M.toggle("vsync")
end

function M.toggleDebug()
    return M.toggle("debug")
end

function M.formatValue(option)
    local value = M[option.key]
    if option.type == "toggle" then
        return value and "ON" or "OFF"
    end
    if option.key:find("Volume") or option.key:find("volume") then
        return tostring(math.floor(value * 100 + 0.5)) .. "%"
    end
    if option.key == "cameraSpeed" then
        return string.format("%.2gx", value)
    end
    return tostring(value)
end

return M
