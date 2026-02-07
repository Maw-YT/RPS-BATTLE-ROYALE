local slash = {}
slash.__index = slash

function slash:new(x, y, angle)
    local instance = setmetatable({}, slash)
    instance.x = x
    instance.y = y
    instance.angle = angle or math.random() * math.pi * 2
    instance.length = 0
    instance.maxLength = 50
    instance.life = 0.2 -- Only lasts 0.2 seconds (very fast!)
    instance.maxLife = 0.2
    return instance
end

function slash:update(dt)
    self.life = self.life - dt
    -- Grow the line length over its life
    self.length = self.maxLength * (self.life / self.maxLife)
end

function slash:draw()
    local alpha = self.life / self.maxLife
    love.graphics.setColor(1, 1, 1, alpha) -- Fades out
    love.graphics.setLineWidth(3)
    
    -- Calculate start and end points based on angle
    local x1 = self.x - math.cos(self.angle) * self.length
    local y1 = self.y - math.sin(self.angle) * self.length
    local x2 = self.x + math.cos(self.angle) * self.length
    local y2 = self.y + math.sin(self.angle) * self.length
    
    love.graphics.line(x1, y1, x2, y2)
    love.graphics.setColor(1, 1, 1, 1) -- Reset
end

return slash