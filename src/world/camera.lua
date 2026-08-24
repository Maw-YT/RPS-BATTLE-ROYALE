local settings = require "src.core.settings"

local M = {}
M.__index = M

function M.new()
    local instance = setmetatable({}, M)
    instance.x = 0
    instance.y = 0
    instance.scale = 1
    instance.targetScale = 1
    instance.minScale = 0.2
    instance.maxScale = 3
    instance.zoomSpeed = 0.1
    instance.panSpeed = 500
    instance.edgePanMargin = 50
    instance.edgePanSpeed = 400
    return instance
end

function M:update(dt, screenWidth, screenHeight)
    if self.scale ~= self.targetScale then
        local diff = self.targetScale - self.scale
        self.scale = self.scale + diff * 10 * dt
        if math.abs(diff) < 0.01 then
            self.scale = self.targetScale
        end
    end

    local speedMul = settings.cameraSpeed or 1
    local keyPanAmount = self.panSpeed * speedMul * dt / self.scale
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        self.x = self.x - keyPanAmount
    end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        self.x = self.x + keyPanAmount
    end
    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
        self.y = self.y - keyPanAmount
    end
    if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
        self.y = self.y + keyPanAmount
    end

    if settings.edgePan then
        local mx, my = love.mouse.getPosition()
        local edge = self.edgePanMargin
        local edgeAmount = self.edgePanSpeed * speedMul * dt / self.scale
        if mx < edge then
            self.x = self.x - edgeAmount
        elseif mx > screenWidth - edge then
            self.x = self.x + edgeAmount
        end
        if my < edge then
            self.y = self.y - edgeAmount
        elseif my > screenHeight - edge then
            self.y = self.y + edgeAmount
        end
    end
end

function M:zoom(direction, mouseX, mouseY)
    local worldX, worldY = mouseX / self.scale + self.x, mouseY / self.scale + self.y
    self.targetScale = self.targetScale + direction * self.zoomSpeed
    self.targetScale = math.max(self.minScale, math.min(self.maxScale, self.targetScale))
    self.scale = self.targetScale
    self.x = worldX - mouseX / self.scale
    self.y = worldY - mouseY / self.scale
end

function M:pan(dx, dy)
    self.x = self.x + dx / self.scale
    self.y = self.y + dy / self.scale
end

function M:setPosition(x, y)
    self.x = x
    self.y = y
end

function M:clampToWorld(worldWidth, worldHeight, screenWidth, screenHeight)
    local halfW = screenWidth / 2 / self.scale
    local halfH = screenHeight / 2 / self.scale
    self.x = math.max(-halfW, math.min(worldWidth - halfW, self.x))
    self.y = math.max(-halfH, math.min(worldHeight - halfH, self.y))
end

function M:begin()
    love.graphics.push()
    love.graphics.scale(self.scale)
    love.graphics.translate(-self.x, -self.y)
end

function M:endDraw()
    love.graphics.pop()
end

function M:screenToWorld(screenX, screenY)
    return screenX / self.scale + self.x, screenY / self.scale + self.y
end

function M:worldToScreen(worldX, worldY)
    return (worldX - self.x) * self.scale, (worldY - self.y) * self.scale
end

return M
