local M = {}
M.__index = M

local audio = require "src.audio"
local rules = { rock = "scissors", scissors = "paper", paper = "rock" }

function M.new(grid, frustum, camera)
    local instance = setmetatable({}, M)
    instance.grid = grid
    instance.frustum = frustum
    instance.camera = camera
    instance.dashDist = 60
    instance.zipSpeed = 1000
    instance.soundRange = 400
    instance.nearbyScratch = {}
    return instance
end

function M:checkCollision(b1, b2)
    if b1 == b2 or b1.dead or b2.dead then
        return nil
    end

    if b1.frozenTimer > 0 or b2.frozenTimer > 0 then
        return nil
    end

    local dx, dy = b2.x - b1.x, b2.y - b1.y
    local distSq = dx * dx + dy * dy

    if distSq < (b1.size + b2.size) ^ 2 then
        if rules[b1.type] == b2.type then
            return b1, b2
        elseif rules[b2.type] == b1.type then
            return b2, b1
        end
    end

    return nil
end

function M:playSlash(x, y)
    audio.playWorld("slash", x, y, self.frustum, self.camera)
end

function M:processKill(killer, victim, slashes, slashModule, tilegrid, worldWidth, worldHeight)
    local speed = math.sqrt(killer.vx ^ 2 + killer.vy ^ 2)
    if speed == 0 then
        return
    end

    local dirX = killer.vx / speed
    local dirY = killer.vy / speed

    local zipX = victim.x + (dirX * self.dashDist)
    local zipY = victim.y + (dirY * self.dashDist)

    if tilegrid then
        local canZip = killer:canMoveTo(zipX, zipY, tilegrid)

        if zipX < killer.size or zipX > worldWidth - killer.size or
           zipY < killer.size or zipY > worldHeight - killer.size then
            canZip = false
        end

        if not canZip then
            tilegrid:damageWallAt(zipX, zipY, 3, killer.size)
            local found = false
            local baseAngle = math.atan2(dirY, dirX)
            for angleOffset = 0, math.pi * 2, math.pi / 4 do
                local testDirX = math.cos(baseAngle + angleOffset)
                local testDirY = math.sin(baseAngle + angleOffset)
                local testX = victim.x + (testDirX * self.dashDist)
                local testY = victim.y + (testDirY * self.dashDist)

                if killer:canMoveTo(testX, testY, tilegrid) and
                   testX > killer.size and testX < worldWidth - killer.size and
                   testY > killer.size and testY < worldHeight - killer.size then
                    zipX = testX
                    zipY = testY
                    dirX = testDirX
                    dirY = testDirY
                    found = true
                    break
                end
            end

            if not found then
                zipX = victim.x
                zipY = victim.y
            end
        end
    end

    killer.x = zipX
    killer.y = zipY
    killer.vx = dirX * self.zipSpeed
    killer.vy = dirY * self.zipSpeed

    victim.dead = true
    table.insert(slashes, slashModule:new(victim.x, victim.y, math.atan2(dirY, dirX)))

    killer.killCount = killer.killCount + 1
    killer.killTimer = 1.0

    if killer.killCount >= 2 then
        killer.showDoubleKill = 1.5
    end

    self:playSlash(killer.x, killer.y)
end

function M:resolveCollisions(balls, slashes, slashModule, tilegrid, worldWidth, worldHeight)
    for _, b1 in ipairs(balls) do
        if not b1.dead then
            local nearby = self.grid:getNearbyEntities(b1.x, b1.y, self.nearbyScratch)
            for i = 1, #nearby do
                local b2 = nearby[i]
                if b2.id > b1.id then
                    local killer, victim = self:checkCollision(b1, b2)
                    if killer and victim then
                        self:processKill(killer, victim, slashes, slashModule, tilegrid, worldWidth, worldHeight)
                    end
                end
            end
        end
    end
end

return M
