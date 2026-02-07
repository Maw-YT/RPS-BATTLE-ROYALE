local ball = {}
ball.__index = ball

local images = {
    rock = love.graphics.newImage("assets/rock.png"),
    paper = love.graphics.newImage("assets/paper.png"),
    scissors = love.graphics.newImage("assets/scissors.png")
}
debug = false

function ball:new(x, y, bType)
    local instance = setmetatable({}, ball)
    instance.x = x
    instance.y = y
    instance.size = 20
    instance.type = bType
    instance.vx = math.random(-120, 120)
    instance.vy = math.random(-120, 120)
    instance.dead = false
    instance.trail = {}
    instance.killCount = 0
    instance.killTimer = 0
    instance.showDoubleKill = 0 -- How long to show the text on screen
    return instance
end

function ball:update(dt, targets)
    -- 1. STEERING / BENDING LOGIC
    local rules = { rock = "scissors", scissors = "paper", paper = "rock" }
    local killerRules = { scissors = "rock", paper = "scissors", rock = "paper" }
    
    local targetType = rules[self.type]   -- What I want to eat
    local hunterType = killerRules[self.type] -- What wants to eat me
    
    local huntForce = 500
    local fleeForce = 250 -- "Not good running" (half the strength of hunting)
    local huntRange = 300
    local fleeRange = 250 -- Only runs when they are close
    
    for _, other in ipairs(targets) do
        if not other.dead then
            local dx = other.x - self.x
            local dy = other.y - self.y
            local dist = math.sqrt(dx*dx + dy*dy)
            
            -- HUNTING (Bend towards victims)
            if other.type == targetType and dist < huntRange then
                self.vx = self.vx + (dx/dist) * huntForce * dt
                self.vy = self.vy + (dy/dist) * huntForce * dt
            
            -- RUNNING (Nudge away from predators)
            elseif other.type == hunterType and dist < fleeRange then
                self.vx = self.vx - (dx/dist) * fleeForce * dt
                self.vy = self.vy - (dy/dist) * fleeForce * dt
                self.debugTarget = nearestTarget
            end
        end
    end

    -- 2. FRICTION (Slow down after a zip)
    local speed = math.sqrt(self.vx^2 + self.vy^2)
    local normalSpeed = 120
    if speed > normalSpeed then
        local friction = 2.0
        self.vx = self.vx - (self.vx * friction * dt)
        self.vy = self.vy - (self.vy * friction * dt)
    end

    -- 3. APPLY MOVEMENT
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    -- Decrease kill timer
    if self.killTimer > 0 then
        self.killTimer = self.killTimer - dt
    else
        self.killCount = 0 -- Reset if too much time passed
    end

    -- Decrease double kill text visibility
    if self.showDoubleKill > 0 then
        self.showDoubleKill = self.showDoubleKill - dt
    end

    -- 4. OUT OF BOUNDS PROTECTION
    local w, h = love.graphics.getDimensions()
    if self.x < self.size then self.x = self.size; self.vx = math.abs(self.vx)
    elseif self.x > w - self.size then self.x = w - self.size; self.vx = -math.abs(self.vx) end
    if self.y < self.size then self.y = self.size; self.vy = math.abs(self.vy)
    elseif self.y > h - self.size then self.y = h - self.size; self.vy = -math.abs(self.vy) end
end

function ball:draw()
    local img = images[self.type]
    local scale = (self.size * 2) / img:getWidth()
    
    for i, p in ipairs(self.trail) do
        love.graphics.setColor(1, 1, 1, i/#self.trail * 0.3)
        love.graphics.draw(img, p.x, p.y, 0, scale, scale, img:getWidth()/2, img:getHeight()/2)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(img, self.x, self.y, 0, scale, scale, img:getWidth()/2, img:getHeight()/2)
    -- Draw "DOUBLE KILL" text above the ball
    if self.showDoubleKill > 0 then
        local text = "DOUBLE KILL!"
        local color = {1, 1, 0} -- Yellow (Double)
        
        if self.killCount == 3 then
            text = "TRIPLE KILL!!"
            color = {1, 0.5, 0} -- Orange (Triple)
        elseif self.killCount == 4 then
            text = "Quadruple KILL!!!"
            color = {1, 0, 0} -- Red (Quadruple)
        elseif self.killCount >= 5 then
            text = "ULTRA KILL!!!!"
            color = {0.8,0,0} -- Dark red (ULTRA)
        end

        love.graphics.setColor(color)
        local scale = 1 + (self.showDoubleKill * 0.5)
        -- Centering the text above the ball
        love.graphics.print(text, self.x, self.y - 60, 0, scale, scale, 50, 0)
        love.graphics.setColor(1, 1, 1, 1)
    end
    if debug then
        love.graphics.setColor(1,0,0,.5)
        love.graphics.setLineWidth(1)
        love.graphics.circle("line", self.x, self.y, self.size) -- hitbox
        love.graphics.circle("line", self.x, self.y, 300) -- hunt range
        love.graphics.setColor(0,1,0,.5)
        love.graphics.circle("line", self.x, self.y, 250)
    end
end

return ball