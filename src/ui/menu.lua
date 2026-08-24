local settingsMenu = require "src.ui.settings_menu"

local M = {}
M.__index = M

local function pointInRect(x, y, r)
    return x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h
end

function M.new()
    local instance = setmetatable({}, M)
    instance.hover = nil
    instance.selected = 1
    instance.fonts = {
        title = love.graphics.newFont(56),
        subtitle = love.graphics.newFont(18),
        button = love.graphics.newFont(26),
        cardTitle = love.graphics.newFont(28),
        body = love.graphics.newFont(16),
        small = love.graphics.newFont(14)
    }
    instance.images = {
        rock = love.graphics.newImage("assets/rock.png"),
        paper = love.graphics.newImage("assets/paper.png"),
        scissors = love.graphics.newImage("assets/scissors.png")
    }
    instance.settingsPanel = settingsMenu.new(instance.fonts)
    return instance
end

function M:getButtons(scene, sW, sH)
    if scene == "main_menu" then
        local bw, bh = 300, 60
        local cx = sW / 2 - bw / 2
        local cy = sH / 2 - 40
        return {
            {id = "play", label = "PLAY", x = cx, y = cy, w = bw, h = bh},
            {id = "settings", label = "SETTINGS", x = cx, y = cy + 80, w = bw, h = bh},
            {id = "quit", label = "QUIT", x = cx, y = cy + 160, w = bw, h = bh}
        }
    elseif scene == "gamemode_menu" then
        local cardW, cardH = 360, 300
        local gap = 48
        local stacked = sW < cardW * 2 + gap + 80
        local buttons

        if stacked then
            local startX = sW / 2 - cardW / 2
            local startY = sH / 2 - 280
            buttons = {
                {id = "fortnite", kind = "card", label = "Fortnite Mode", tagline = "Battle Royale", description = "Huge world with walls, loot chests, freeze rays, and a free camera.", x = startX, y = startY, w = cardW, h = cardH},
                {id = "simple", kind = "card", label = "Simple Mode", tagline = "Classic Arena", description = "Fits the screen. No tiles, no camera, and no freeze rays.", x = startX, y = startY + cardH + 24, w = cardW, h = cardH}
            }
            buttons[3] = {
                id = "back",
                label = "BACK",
                x = sW / 2 - 110,
                y = buttons[2].y + cardH + 28,
                w = 220,
                h = 50
            }
        else
            local totalW = cardW * 2 + gap
            local startX = sW / 2 - totalW / 2
            local startY = sH / 2 - cardH / 2 + 24
            buttons = {
                {id = "fortnite", kind = "card", label = "Fortnite Mode", tagline = "Battle Royale", description = "Huge world with walls, loot chests, freeze rays, and a free camera.", x = startX, y = startY, w = cardW, h = cardH},
                {id = "simple", kind = "card", label = "Simple Mode", tagline = "Classic Arena", description = "Fits the screen. No tiles, no camera, and no freeze rays.", x = startX + cardW + gap, y = startY, w = cardW, h = cardH},
                {id = "back", label = "BACK", x = sW / 2 - 110, y = startY + cardH + 36, w = 220, h = 50}
            }
        end
        return buttons
    end
    return {}
end

function M:updateHover(scene)
    local sW, sH = love.graphics.getDimensions()
    local mx, my = love.mouse.getPosition()
    local buttons = self:getButtons(scene, sW, sH)
    self.hover = nil
    for i, btn in ipairs(buttons) do
        if pointInRect(mx, my, btn) then
            self.hover = btn.id
            if btn.id ~= "back" then
                self.selected = i
            end
            break
        end
    end
end

function M:keypressed(key, scene)
    if scene == "settings_menu" then
        return self.settingsPanel:keypressed(key)
    end

    local sW, sH = love.graphics.getDimensions()
    local buttons = self:getButtons(scene, sW, sH)
    if #buttons == 0 then
        return nil
    end

    if key == "up" or key == "w" or key == "left" or key == "a" then
        self.selected = self.selected - 1
        if self.selected < 1 then
            self.selected = #buttons
        end
        self.hover = buttons[self.selected].id
    elseif key == "down" or key == "s" or key == "right" or key == "d" then
        self.selected = self.selected + 1
        if self.selected > #buttons then
            self.selected = 1
        end
        self.hover = buttons[self.selected].id
    elseif key == "return" or key == "space" then
        local btn = buttons[self.selected]
        return btn and btn.id or nil
    elseif key == "escape" then
        if scene == "gamemode_menu" then
            return "back"
        elseif scene == "main_menu" then
            return "quit"
        end
    end
    return nil
end

function M:wheelmoved(y, scene)
    if scene == "settings_menu" then
        self.settingsPanel:wheelmoved(y)
    end
end

function M:mousepressed(x, y, scene)
    if scene == "settings_menu" then
        return self.settingsPanel:mousepressed(x, y)
    end
    return self:click(x, y, scene)
end

function M:mousemoved(x, y, scene)
    if scene == "settings_menu" then
        self.settingsPanel:mousemoved(x, y)
    end
end

function M:mousereleased(scene)
    if scene == "settings_menu" then
        return self.settingsPanel:mousereleased()
    end
    return nil
end

function M:click(x, y, scene)
    local sW, sH = love.graphics.getDimensions()
    for _, btn in ipairs(self:getButtons(scene, sW, sH)) do
        if pointInRect(x, y, btn) then
            return btn.id
        end
    end
    return nil
end

function M:drawBackground(sW, sH)
    love.graphics.setColor(0.05, 0.05, 0.07)
    love.graphics.rectangle("fill", 0, 0, sW, sH)

    local t = love.timer.getTime()
    local types = {"rock", "paper", "scissors"}
    for i, name in ipairs(types) do
        local img = self.images[name]
        local angle = t * 0.15 + i * (math.pi * 2 / 3)
        local radius = math.min(sW, sH) * 0.28
        local x = sW / 2 + math.cos(angle) * radius
        local y = sH / 2 + math.sin(angle) * radius * 0.55
        local scale = 0.55 + math.sin(t * 0.8 + i) * 0.05
        love.graphics.setColor(1, 1, 1, 0.08)
        love.graphics.draw(img, x, y, angle * 0.25, scale, scale, img:getWidth() / 2, img:getHeight() / 2)
    end
end

function M:drawButton(btn, hovered)
    if hovered then
        love.graphics.setColor(0.95, 0.82, 0.25, 0.95)
        love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 8)
        love.graphics.setColor(0.08, 0.08, 0.1)
    else
        love.graphics.setColor(0.12, 0.12, 0.16, 0.92)
        love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 8)
        love.graphics.setColor(0.75, 0.75, 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 8)
        love.graphics.setColor(1, 1, 1)
    end
    love.graphics.setFont(self.fonts.button)
    love.graphics.printf(btn.label, btn.x, btn.y + btn.h / 2 - 16, btn.w, "center")
end

function M:drawCard(btn, hovered)
    if hovered then
        love.graphics.setColor(0.16, 0.16, 0.22, 0.96)
        love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 12)
        love.graphics.setColor(0.95, 0.82, 0.25)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 12)
    else
        love.graphics.setColor(0.10, 0.10, 0.14, 0.92)
        love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 12)
        love.graphics.setColor(0.35, 0.35, 0.42)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 12)
    end

    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(0.95, 0.82, 0.25, hovered and 1 or 0.7)
    love.graphics.printf(string.upper(btn.tagline), btn.x + 24, btn.y + 36, btn.w - 48, "center")

    love.graphics.setFont(self.fonts.cardTitle)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(btn.label, btn.x + 20, btn.y + 70, btn.w - 40, "center")

    love.graphics.setFont(self.fonts.body)
    love.graphics.setColor(0.72, 0.72, 0.78)
    love.graphics.printf(btn.description, btn.x + 28, btn.y + 130, btn.w - 56, "center")

    local prompt = hovered and "Click or press Enter" or "Select"
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(hovered and 0.95 or 0.5, hovered and 0.82 or 0.5, hovered and 0.25 or 0.55)
    love.graphics.printf(prompt, btn.x, btn.y + btn.h - 48, btn.w, "center")
end

function M:drawMainMenu()
    local sW, sH = love.graphics.getDimensions()
    self:updateHover("main_menu")
    self:drawBackground(sW, sH)

    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("RPS BATTLE ROYALE", 0, sH / 2 - 220, sW, "center")

    love.graphics.setFont(self.fonts.subtitle)
    love.graphics.setColor(0.95, 0.82, 0.25)
    love.graphics.printf("ROCK  ·  PAPER  ·  SCISSORS", 0, sH / 2 - 150, sW, "center")

    local buttons = self:getButtons("main_menu", sW, sH)
    for i, btn in ipairs(buttons) do
        local hovered = (self.hover == btn.id) or (not self.hover and self.selected == i)
        self:drawButton(btn, hovered)
    end

    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(1, 1, 1, 0.4)
    love.graphics.printf("WASD / Arrows to navigate  ·  Enter to select  ·  Esc to quit", 0, sH - 36, sW, "center")
end

function M:drawGamemodeMenu()
    local sW, sH = love.graphics.getDimensions()
    self:updateHover("gamemode_menu")
    self:drawBackground(sW, sH)

    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("SELECT GAMEMODE", 0, 70, sW, "center")

    love.graphics.setFont(self.fonts.subtitle)
    love.graphics.setColor(0.7, 0.7, 0.76)
    love.graphics.printf("Choose how the arena works", 0, 140, sW, "center")

    local buttons = self:getButtons("gamemode_menu", sW, sH)
    for i, btn in ipairs(buttons) do
        local hovered = (self.hover == btn.id) or (not self.hover and self.selected == i)
        if btn.kind == "card" then
            self:drawCard(btn, hovered)
        else
            self:drawButton(btn, hovered)
        end
    end

    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(1, 1, 1, 0.4)
    love.graphics.printf("Esc to go back", 0, sH - 36, sW, "center")
end

function M:drawSettingsMenu()
    local sW, sH = love.graphics.getDimensions()
    self:drawBackground(sW, sH)

    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("SETTINGS", 0, 48, sW, "center")

    love.graphics.setFont(self.fonts.subtitle)
    love.graphics.setColor(0.7, 0.7, 0.76)
    love.graphics.printf("Pick a category, then click or drag", 0, 118, sW, "center")

    self.settingsPanel:draw()
end

return M
