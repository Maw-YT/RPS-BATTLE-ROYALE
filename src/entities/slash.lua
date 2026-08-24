local slash = {}
slash.__index = slash

function slash:new(x, y, angle)
    local instance = setmetatable({}, slash)
    instance.x = x
    instance.y = y
    instance.angle = angle or math.random() * math.pi * 2
    instance.length = 0
    instance.maxLength = 50
    instance.life = 0.2
    instance.maxLife = 0.2
    instance.prevLife = instance.life
    instance.prevLength = instance.length
    return instance
end

function slash:savePrevious()
    self.prevLife = self.life
    self.prevLength = self.length
end

function slash:update(dt)
    self.life = self.life - dt
    self.length = self.maxLength * (self.life / self.maxLife)
end

function slash:draw(alpha, frustum, camera, screenWidth, screenHeight)
    alpha = alpha or 1
    local prevLife = self.prevLife or self.life
    local prevLength = self.prevLength or self.length
    local drawLife = prevLife + (self.life - prevLife) * alpha
    local drawLength = prevLength + (self.length - prevLength) * alpha

    if frustum and camera then
        if not frustum:isCircleVisible(self.x, self.y, 30, camera, screenWidth, screenHeight) then
            return
        end
    end

    local fade = drawLife / self.maxLife
    love.graphics.setColor(1, 1, 1, fade)
    love.graphics.setLineWidth(3)

    local x1 = self.x - math.cos(self.angle) * drawLength
    local y1 = self.y - math.sin(self.angle) * drawLength
    local x2 = self.x + math.cos(self.angle) * drawLength
    local y2 = self.y + math.sin(self.angle) * drawLength

    love.graphics.line(x1, y1, x2, y2)
    love.graphics.setColor(1, 1, 1, 1)
end

return slash
