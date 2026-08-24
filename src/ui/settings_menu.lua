local settings = require "src.core.settings"

local M = {}
M.__index = M

local ROW_H = 54
local ROW_GAP = 10
local TRACK_W = 196
local TRACK_H = 10
local KNOB_R = 9

local function pointInRect(x, y, r)
    return x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h
end

local function sliderT(option)
    if option.max == option.min then
        return 0
    end
    return (settings[option.key] - option.min) / (option.max - option.min)
end

function M.new(fonts)
    local instance = setmetatable({}, M)
    instance.fonts = fonts
    instance.category = "Display"
    instance.selected = 1
    instance.hover = nil
    instance.drag = nil
    instance.optionScroll = 0
    return instance
end

function M:reset()
    self.category = "Display"
    self.selected = 1
    self.hover = nil
    self.drag = nil
    self.optionScroll = 0
end

function M:layout(sW, sH)
    local cats = settings.categories()
    local panelW = math.min(920, sW - 80)
    local panelX = (sW - panelW) / 2
    local panelY = 168
    local panelH = sH - 280
    local catW = 210
    local listX = panelX + catW + 28
    local listW = panelW - catW - 28
    local back = {
        id = "back",
        x = sW / 2 - 150,
        y = sH - 92,
        w = 300,
        h = 50
    }

    local catButtons = {}
    for i, name in ipairs(cats) do
        catButtons[i] = {
            kind = "category",
            id = "cat_" .. name,
            name = name,
            x = panelX,
            y = panelY + (i - 1) * 58,
            w = catW,
            h = 48
        }
    end

    local options = settings.optionsIn(self.category)
    local listTop = panelY
    local listBottom = panelY + panelH
    local visible = math.max(1, math.floor((listBottom - listTop + ROW_GAP) / (ROW_H + ROW_GAP)))
    local maxScroll = math.max(0, #options - visible)
    if self.optionScroll > maxScroll then
        self.optionScroll = maxScroll
    end
    if self.selected < 1 then
        self.selected = 1
    elseif self.selected > #options then
        self.selected = math.max(1, #options)
    end
    if self.selected <= self.optionScroll then
        self.optionScroll = math.max(0, self.selected - 1)
    elseif self.selected > self.optionScroll + visible then
        self.optionScroll = self.selected - visible
    end

    local rows = {}
    local startIndex = self.optionScroll + 1
    local endIndex = math.min(#options, self.optionScroll + visible)
    local row = 0
    for i = startIndex, endIndex do
        local option = options[i]
        local y = listTop + row * (ROW_H + ROW_GAP)
        local btn = {
            kind = option.type,
            id = option.key,
            option = option,
            index = i,
            x = listX,
            y = y,
            w = listW,
            h = ROW_H
        }
        if option.type == "slider" then
            local barX = listX + listW - TRACK_W - 86
            local barY = y + ROW_H / 2 - TRACK_H / 2
            btn.bar = {x = barX, y = barY, w = TRACK_W, h = TRACK_H}
            btn.sliderHit = {
                x = barX - 16,
                y = y,
                w = TRACK_W + 32 + 78,
                h = ROW_H
            }
        end
        rows[#rows + 1] = btn
        row = row + 1
    end

    return {
        cats = cats,
        catButtons = catButtons,
        options = options,
        rows = rows,
        back = back,
        panelX = panelX,
        panelY = panelY,
        panelW = panelW,
        panelH = panelH,
        listX = listX,
        listW = listW,
        visible = visible
    }
end

function M:setCategory(name)
    if self.category == name then
        return
    end
    self.category = name
    self.selected = 1
    self.optionScroll = 0
    self.hover = nil
end

local function applySliderFromMouse(btn, mx, persist)
    local t = (mx - btn.bar.x) / btn.bar.w
    settings.setSliderT(btn.id, t, persist)
end

function M:updateHover()
    if self.drag then
        return
    end
    local sW, sH = love.graphics.getDimensions()
    local layout = self:layout(sW, sH)
    local mx, my = love.mouse.getPosition()
    self.hover = nil
    if pointInRect(mx, my, layout.back) then
        self.hover = "back"
        return
    end
    for _, cat in ipairs(layout.catButtons) do
        if pointInRect(mx, my, cat) then
            self.hover = cat.id
            return
        end
    end
    for _, row in ipairs(layout.rows) do
        if pointInRect(mx, my, row) then
            self.hover = row.id
            self.selected = row.index
            return
        end
    end
end

function M:mousepressed(x, y)
    local sW, sH = love.graphics.getDimensions()
    local layout = self:layout(sW, sH)
    if pointInRect(x, y, layout.back) then
        return "back"
    end
    for _, cat in ipairs(layout.catButtons) do
        if pointInRect(x, y, cat) then
            self:setCategory(cat.name)
            return "settings_changed"
        end
    end
    for _, row in ipairs(layout.rows) do
        if row.kind == "slider" and row.sliderHit and pointInRect(x, y, row.sliderHit) then
            self.drag = {key = row.id, bar = row.bar, option = row.option}
            self.selected = row.index
            applySliderFromMouse(row, x, true)
            return "settings_changed"
        elseif row.kind == "toggle" and pointInRect(x, y, row) then
            self.selected = row.index
            settings.toggle(row.id)
            return "settings_changed"
        end
    end
    return nil
end

function M:mousemoved(x, y)
    if not self.drag then
        return
    end
    local sW, sH = love.graphics.getDimensions()
    local layout = self:layout(sW, sH)
    for _, row in ipairs(layout.rows) do
        if row.id == self.drag.key and row.bar then
            self.drag.bar = row.bar
            applySliderFromMouse(row, x, true)
            return
        end
    end
    applySliderFromMouse({id = self.drag.key, bar = self.drag.bar}, x, true)
end

function M:mousereleased()
    if self.drag then
        settings.save()
        self.drag = nil
        return "settings_changed"
    end
    return nil
end

function M:wheelmoved(y)
    if self.drag then
        return
    end
    local sW, sH = love.graphics.getDimensions()
    local layout = self:layout(sW, sH)
    local maxScroll = math.max(0, #layout.options - layout.visible)
    self.optionScroll = math.max(0, math.min(maxScroll, self.optionScroll - y))
end

function M:keypressed(key)
    local options = settings.optionsIn(self.category)
    local cats = settings.categories()
    local catIndex = 1
    for i, name in ipairs(cats) do
        if name == self.category then
            catIndex = i
            break
        end
    end

    if key == "escape" then
        return "back"
    elseif key == "tab" then
        local nextIndex = catIndex + ((love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) and -1 or 1)
        if nextIndex < 1 then
            nextIndex = #cats
        elseif nextIndex > #cats then
            nextIndex = 1
        end
        self:setCategory(cats[nextIndex])
        return "settings_changed"
    elseif key == "up" or key == "w" then
        self.selected = self.selected - 1
        if self.selected < 1 then
            self.selected = #options
        end
    elseif key == "down" or key == "s" then
        self.selected = self.selected + 1
        if self.selected > #options then
            self.selected = 1
        end
    elseif key == "return" or key == "space" then
        local option = options[self.selected]
        if option and option.type == "toggle" then
            settings.toggle(option.key)
            return "settings_changed"
        end
    end
    return nil
end

function M:drawCategoryButton(btn, active, hovered)
    if active then
        love.graphics.setColor(0.95, 0.82, 0.25, 0.95)
        love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 8)
        love.graphics.setColor(0.08, 0.08, 0.1)
    elseif hovered then
        love.graphics.setColor(0.18, 0.18, 0.24, 0.96)
        love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 8)
        love.graphics.setColor(0.95, 0.82, 0.25)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 8)
        love.graphics.setColor(1, 1, 1)
    else
        love.graphics.setColor(0.10, 0.10, 0.14, 0.92)
        love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 8)
        love.graphics.setColor(0.32, 0.32, 0.38)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 8)
        love.graphics.setColor(0.82, 0.82, 0.88)
    end
    love.graphics.setFont(self.fonts.body)
    love.graphics.printf(btn.name, btn.x + 12, btn.y + btn.h / 2 - 10, btn.w - 24, "left")
end

function M:drawToggle(btn, hovered)
    local on = settings[btn.id]
    local knobW, knobH = 52, 26
    local kx = btn.x + btn.w - knobW - 18
    local ky = btn.y + btn.h / 2 - knobH / 2
    love.graphics.setColor(on and 0.28 or 0.22, on and 0.62 or 0.22, on and 0.38 or 0.26, 1)
    love.graphics.rectangle("fill", kx, ky, knobW, knobH, 13)
    local thumbX = on and (kx + knobW - 13) or (kx + 13)
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", thumbX, ky + knobH / 2, 9)
    love.graphics.setColor(hovered and 0.95 or 0.75, hovered and 0.82 or 0.75, hovered and 0.25 or 0.8)
    love.graphics.setFont(self.fonts.small)
    love.graphics.printf(on and "ON" or "OFF", kx - 54, btn.y + btn.h / 2 - 8, 48, "right")
end

function M:drawSlider(btn, hovered)
    local t = sliderT(btn.option)
    local bar = btn.bar
    local dragging = self.drag and self.drag.key == btn.id
    local active = hovered or dragging

    love.graphics.setColor(0.18, 0.18, 0.22)
    love.graphics.rectangle("fill", bar.x, bar.y - 3, bar.w, bar.h + 6, 6)

    love.graphics.setColor(0.95, 0.82, 0.25)
    love.graphics.rectangle("fill", bar.x, bar.y - 3, bar.w * t, bar.h + 6, 6)

    local knobX = bar.x + bar.w * t
    local knobY = bar.y + bar.h / 2
    if active then
        love.graphics.setColor(1, 1, 1, 0.18)
        love.graphics.circle("fill", knobX, knobY, KNOB_R + 7)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", knobX, knobY, KNOB_R)
    love.graphics.setColor(0.95, 0.82, 0.25)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", knobX, knobY, KNOB_R)

    love.graphics.setFont(self.fonts.body)
    love.graphics.setColor(active and 0.95 or 0.85, active and 0.82 or 0.85, active and 0.25 or 0.9)
    love.graphics.printf(settings.formatValue(btn.option), btn.x + btn.w - 78, btn.y + btn.h / 2 - 10, 62, "right")
end

function M:drawRow(btn, hovered)
    if hovered or (self.drag and self.drag.key == btn.id) then
        love.graphics.setColor(0.16, 0.16, 0.22, 0.96)
        love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 8)
        love.graphics.setColor(0.95, 0.82, 0.25)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 8)
    else
        love.graphics.setColor(0.10, 0.10, 0.14, 0.92)
        love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 8)
        love.graphics.setColor(0.32, 0.32, 0.38)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 8)
    end

    love.graphics.setFont(self.fonts.body)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(btn.option.label, btn.x + 18, btn.y + btn.h / 2 - 10)

    if btn.kind == "slider" then
        self:drawSlider(btn, hovered)
    else
        self:drawToggle(btn, hovered)
    end
end

function M:drawBack(btn, hovered)
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
    love.graphics.printf("BACK", btn.x, btn.y + btn.h / 2 - 16, btn.w, "center")
end

function M:draw()
    local sW, sH = love.graphics.getDimensions()
    self:updateHover()
    local layout = self:layout(sW, sH)

    love.graphics.setFont(self.fonts.subtitle)
    love.graphics.setColor(0.95, 0.82, 0.25)
    love.graphics.printf(string.upper(self.category), layout.listX, layout.panelY - 36, layout.listW, "left")

    for _, cat in ipairs(layout.catButtons) do
        self:drawCategoryButton(cat, cat.name == self.category, self.hover == cat.id)
    end

    for _, row in ipairs(layout.rows) do
        local hovered = self.hover == row.id or (not self.hover and row.index == self.selected)
        self:drawRow(row, hovered)
    end

    self:drawBack(layout.back, self.hover == "back")

    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(1, 1, 1, 0.4)
    love.graphics.printf("Click a category  ·  Drag sliders  ·  Click switches  ·  Esc to go back", 0, sH - 36, sW, "center")
end

return M
