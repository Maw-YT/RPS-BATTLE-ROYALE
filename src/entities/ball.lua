local settings = require "src.core.settings"
local freeze = require "src.entities.freeze"

local ball = {}
ball.__index = ball

local images = {
    rock = love.graphics.newImage("assets/rock.png"),
    paper = love.graphics.newImage("assets/paper.png"),
    scissors = love.graphics.newImage("assets/scissors.png")
}

local batches = {
    rock = love.graphics.newSpriteBatch(images.rock, 2048, "stream"),
    paper = love.graphics.newSpriteBatch(images.paper, 2048, "stream"),
    scissors = love.graphics.newSpriteBatch(images.scissors, 2048, "stream")
}

local nearbyScratch = {}
local nextId = 1
local huntForce = 500
local fleeForce = 500
local huntRange = 300
local fleeRange = 250
local huntRangeSq = huntRange * huntRange
local fleeRangeSq = fleeRange * fleeRange
local maxNearby = 10
local rules = { rock = "scissors", scissors = "paper", paper = "rock" }
local killerRules = { scissors = "rock", paper = "scissors", rock = "paper" }

function ball:new(x, y, bType)
    local instance = setmetatable({}, ball)
    instance.id = nextId
    nextId = nextId + 1
    instance.x = x
    instance.y = y
    instance.size = 20
    instance.type = bType
    instance.vx = math.random(-120, 120)
    instance.vy = math.random(-120, 120)
    instance.dead = false
    instance.killCount = 0
    instance.killTimer = 0
    instance.showDoubleKill = 0
    instance.hasFreezeRay = false
    instance.freezeRayCharges = 0
    instance.frozenTimer = 0
    instance.freezeRayCooldown = 0
    instance.freezeShootTimer = 0
    instance.freezeBeams = nil
    instance.shootAimAngle = nil
    instance.prevX = x
    instance.prevY = y
    instance.prevVx = instance.vx
    instance.prevVy = instance.vy
    instance._visible = false
    instance._dx = x
    instance._dy = y
    instance._aim = 0
    instance._muzzleX = x
    instance._muzzleY = y
    instance._holdX = x
    instance._holdY = y
    return instance
end

function ball:savePrevious()
    self.prevX = self.x
    self.prevY = self.y
    self.prevVx = self.vx
    self.prevVy = self.vy
end

function ball.clearEffects()
    freeze.clear()
end

function ball.updateDiscarded(dt)
    freeze.updateDiscarded(dt)
end

function ball.drawDiscarded(alpha, frustum, camera, screenWidth, screenHeight)
    freeze.drawDiscarded(alpha, frustum, camera, screenWidth, screenHeight)
end

local function wallDamageFromSpeed(vx, vy)
    local speed = math.sqrt(vx * vx + vy * vy)
    if speed > 500 then
        return 3
    elseif speed > 220 then
        return 2
    end
    return 1
end

function ball:update(dt, targets, navgrid, worldWidth, worldHeight, tilegrid, spatialGrid)
    if self.killTimer > 0 then
        self.killTimer = self.killTimer - dt
    else
        self.killCount = 0
    end

    if self.showDoubleKill > 0 then
        self.showDoubleKill = self.showDoubleKill - dt
    end

    if self.freezeShootTimer > 0 then
        self.freezeShootTimer = self.freezeShootTimer - dt
        if self.freezeShootTimer <= 0 then
            self.freezeBeams = nil
            self.shootAimAngle = nil
        end
    end

    if self.frozenTimer > 0 then
        self.frozenTimer = self.frozenTimer - dt
        self.vx = 0
        self.vy = 0
        return
    end

    local targetType = rules[self.type]
    local hunterType = killerRules[self.type]

    if navgrid then
        local cx, cy = navgrid:screenToCell(self.x, self.y)
        local bestDx, bestDy = navgrid:getBestDirection(cx, cy, targetType, hunterType, self.x, self.y, self.hasFreezeRay)
        local gridForce = 800
        self.vx = self.vx + bestDx * gridForce * dt
        self.vy = self.vy + bestDy * gridForce * dt
    end

    local nearby
    if spatialGrid then
        nearby = spatialGrid:getNearbyInRange(self.x, self.y, huntRange, nearbyScratch)
    else
        nearby = targets
    end

    local preyCount = 0
    local predCount = 0
    for i = 1, #nearby do
        local other = nearby[i]
        if other ~= self and not other.dead then
            local dx = other.x - self.x
            local dy = other.y - self.y
            local distSq = dx * dx + dy * dy

            if other.type == targetType and distSq < huntRangeSq and preyCount < maxNearby then
                local dist = math.sqrt(distSq)
                if dist > 0 then
                    self.vx = self.vx + (dx / dist) * huntForce * dt
                    self.vy = self.vy + (dy / dist) * huntForce * dt
                    preyCount = preyCount + 1
                end
            elseif other.type == hunterType and distSq < fleeRangeSq and predCount < maxNearby then
                local dist = math.sqrt(distSq)
                if dist > 0 then
                    self.vx = self.vx - (dx / dist) * fleeForce * dt
                    self.vy = self.vy - (dy / dist) * fleeForce * dt
                    predCount = predCount + 1
                end
            end
        end
    end

    local wallAvoidanceForce = 800
    local wallAvoidanceRange = 60

    if self.x < wallAvoidanceRange then
        self.vx = self.vx + wallAvoidanceForce * (1 - self.x / wallAvoidanceRange) * dt
    end
    if self.x > worldWidth - wallAvoidanceRange then
        self.vx = self.vx - wallAvoidanceForce * (1 - (worldWidth - self.x) / wallAvoidanceRange) * dt
    end
    if self.y < wallAvoidanceRange then
        self.vy = self.vy + wallAvoidanceForce * (1 - self.y / wallAvoidanceRange) * dt
    end
    if self.y > worldHeight - wallAvoidanceRange then
        self.vy = self.vy - wallAvoidanceForce * (1 - (worldHeight - self.y) / wallAvoidanceRange) * dt
    end

    local speed = math.sqrt(self.vx * self.vx + self.vy * self.vy)
    local normalSpeed = 120
    if speed > normalSpeed then
        local friction = 2.0
        self.vx = self.vx - (self.vx * friction * dt)
        self.vy = self.vy - (self.vy * friction * dt)
    elseif speed < 20 then
        local minSpeed = 30
        if speed > 0 then
            self.vx = (self.vx / speed) * minSpeed
            self.vy = (self.vy / speed) * minSpeed
        else
            self.vx = (math.random(0, 1) * 2 - 1) * minSpeed
            self.vy = (math.random(0, 1) * 2 - 1) * minSpeed
        end
    end

    local newX = self.x + self.vx * dt
    local newY = self.y + self.vy * dt

    if tilegrid then
        if self:canMoveTo(newX, self.y, tilegrid) then
            self.x = newX
        else
            tilegrid:damageWallAt(newX, self.y, wallDamageFromSpeed(self.vx, self.vy), self.size)
            self.vx = -self.vx * 0.5
        end

        if self:canMoveTo(self.x, newY, tilegrid) then
            self.y = newY
        else
            tilegrid:damageWallAt(self.x, newY, wallDamageFromSpeed(self.vx, self.vy), self.size)
            self.vy = -self.vy * 0.5
        end
    else
        self.x = newX
        self.y = newY
    end

    local w = worldWidth
    local h = worldHeight
    if self.x < self.size then
        self.x = self.size
        self.vx = math.abs(self.vx)
    elseif self.x > w - self.size then
        self.x = w - self.size
        self.vx = -math.abs(self.vx)
    end
    if self.y < self.size then
        self.y = self.size
        self.vy = math.abs(self.vy)
    elseif self.y > h - self.size then
        self.y = h - self.size
        self.vy = -math.abs(self.vy)
    end

    if self.freezeRayCooldown > 0 then
        self.freezeRayCooldown = self.freezeRayCooldown - dt
    end

    if self.hasFreezeRay and self.freezeRayCooldown <= 0 then
        local predatorDistSq = 100 * 100
        local freezeNearby = nearby
        if spatialGrid then
            freezeNearby = spatialGrid:getNearbyInRange(self.x, self.y, 150, nearbyScratch)
        end
        for i = 1, #freezeNearby do
            local other = freezeNearby[i]
            if other ~= self and not other.dead and other.frozenTimer <= 0 and other.type == hunterType then
                local dx = other.x - self.x
                local dy = other.y - self.y
                if dx * dx + dy * dy < predatorDistSq then
                    freeze.use(self, freezeNearby)
                    break
                end
            end
        end
    end
end

function ball:canMoveTo(x, y, tilegrid)
    local size = self.size
    return tilegrid:isWalkable(x, y)
        and tilegrid:isWalkable(x - size, y)
        and tilegrid:isWalkable(x + size, y)
        and tilegrid:isWalkable(x, y - size)
        and tilegrid:isWalkable(x, y + size)
        and tilegrid:isWalkable(x - size, y - size)
        and tilegrid:isWalkable(x + size, y - size)
        and tilegrid:isWalkable(x - size, y + size)
        and tilegrid:isWalkable(x + size, y + size)
end

function ball.beginDraw()
    batches.rock:clear()
    batches.paper:clear()
    batches.scissors:clear()
end

function ball:queueDraw(alpha, frustum, camera, screenWidth, screenHeight)
    alpha = alpha or 1
    local prevX = self.prevX or self.x
    local prevY = self.prevY or self.y
    local prevVx = self.prevVx or self.vx
    local prevVy = self.prevVy or self.vy
    local drawX = prevX + (self.x - prevX) * alpha
    local drawY = prevY + (self.y - prevY) * alpha
    local drawVx = prevVx + (self.vx - prevVx) * alpha
    local drawVy = prevVy + (self.vy - prevVy) * alpha
    self._dx = drawX
    self._dy = drawY

    if frustum and camera and screenWidth and screenHeight then
        if not frustum:isCircleVisible(drawX, drawY, self.size + 80, camera, screenWidth, screenHeight) then
            self._visible = false
            return
        end
    end
    self._visible = true

    freeze.prepareDraw(self, drawX, drawY, drawVx, drawVy)

    if self.frozenTimer > 0 then
        love.graphics.setColor(0.5, 0.8, 1, 0.6)
        love.graphics.circle("fill", drawX, drawY, self.size + 5)
        love.graphics.setColor(0.7, 0.9, 1, 0.8)
        love.graphics.circle("line", drawX, drawY, self.size + 5)
    end

    local img = images[self.type]
    local speed = math.sqrt(drawVx * drawVx + drawVy * drawVy)
    local angle = math.atan2(drawVy, drawVx)
    local flip = 1
    if drawVx < 0 then
        flip = -1
        angle = math.atan2(-drawVy, -drawVx)
    end

    local baseScale = (self.size * 2) / img:getWidth()
    local sx, sy = baseScale * flip, baseScale

    if self.frozenTimer > 0 then
        sx = baseScale * flip
        sy = baseScale
    elseif speed > 200 then
        local stretch = math.min(0.5, (speed - 200) / 400 * 0.5)
        sx = baseScale * (1 + stretch) * flip
        sy = baseScale * (1 - stretch * 0.5)
    elseif speed < 50 then
        local pulse = math.sin(love.timer.getTime() * 5) * 0.05
        sx = baseScale * (1 + pulse) * flip
        sy = baseScale * (1 - pulse)
    end

    local batch = batches[self.type]
    if self.frozenTimer > 0 then
        batch:setColor(0.7, 0.85, 1, 1)
    else
        batch:setColor(1, 1, 1, 1)
    end
    batch:add(drawX, drawY, angle, sx, sy, img:getWidth() / 2, img:getHeight() / 2)
end

function ball.flushDraw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(batches.rock)
    love.graphics.draw(batches.paper)
    love.graphics.draw(batches.scissors)
end

function ball:drawFx()
    if not self._visible then
        return
    end

    local drawX, drawY = self._dx, self._dy

    freeze.drawBeams(self)
    freeze.drawHeld(self)

    if settings.killPopups and self.showDoubleKill > 0 then
        local text = "DOUBLE KILL!"
        local color = {1, 1, 0}

        if self.killCount == 3 then
            text = "TRIPLE KILL!!"
            color = {1, 0.5, 0}
        elseif self.killCount == 4 then
            text = "Quadruple KILL!!!"
            color = {1, 0, 0}
        elseif self.killCount >= 5 then
            text = "ULTRA KILL!!!!"
            color = {0.8, 0, 0}
        end

        love.graphics.setColor(color)
        local scale = 1 + (self.showDoubleKill * 0.5)
        love.graphics.print(text, drawX, drawY - 60, 0, scale, scale, 50, 0)
    end

    if settings.debug then
        love.graphics.setLineWidth(1)
        love.graphics.setColor(1, 0, 0, 0.55)
        love.graphics.circle("line", drawX, drawY, self.size)
        if ball.debugDetail then
            love.graphics.setColor(1, 0.2, 0.2, 0.25)
            love.graphics.circle("line", drawX, drawY, 300)
            love.graphics.setColor(0.2, 1, 0.3, 0.25)
            love.graphics.circle("line", drawX, drawY, 250)
            if self.hasFreezeRay then
                love.graphics.setColor(0.3, 0.85, 1, 0.35)
                love.graphics.circle("line", drawX, drawY, 150)
            end
        end
        local speed = math.sqrt(self.vx * self.vx + self.vy * self.vy)
        if speed > 1 then
            love.graphics.setColor(1, 1, 0, 0.8)
            love.graphics.line(drawX, drawY, drawX + self.vx * 0.18, drawY + self.vy * 0.18)
        end
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print(self.type, drawX - 18, drawY - 38)
        if self.frozenTimer > 0 then
            love.graphics.setColor(0.6, 0.9, 1, 0.9)
            love.graphics.print(string.format("frozen %.1f", self.frozenTimer), drawX - 28, drawY + 22)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return ball
