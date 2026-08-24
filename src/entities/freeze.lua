local audio = require "src.audio"

local freeze = {}

freeze.img = love.graphics.newImage("assets/freeze_ray.png")
freeze.ox = freeze.img:getWidth() * 0.22
freeze.oy = freeze.img:getHeight() * 0.68
freeze.gunScale = 52 / freeze.img:getWidth()
freeze.shootDuration = 0.35
freeze.discardDuration = 0.9

local discardedRays = {}
local killerRules = { scissors = "rock", paper = "scissors", rock = "paper" }

local function lerp(a, b, t)
    return a + (b - a) * t
end

function freeze.clear()
    discardedRays = {}
end

function freeze.spawnDiscarded(x, y, vx, vy, angle)
    local toss = math.atan2(vy, vx)
    if vx == 0 and vy == 0 then
        toss = math.random() * math.pi * 2
    end
    toss = toss + (math.random() - 0.5) * 1.2
    local speed = 160 + math.random() * 90
    discardedRays[#discardedRays + 1] = {
        x = x,
        y = y,
        prevX = x,
        prevY = y,
        vx = math.cos(toss) * speed,
        vy = math.sin(toss) * speed - 140,
        angle = angle or toss,
        spin = (8 + math.random() * 10) * (math.random() < 0.5 and -1 or 1),
        life = freeze.discardDuration,
        maxLife = freeze.discardDuration
    }
end

function freeze.updateDiscarded(dt)
    for i = #discardedRays, 1, -1 do
        local ray = discardedRays[i]
        ray.prevX = ray.x
        ray.prevY = ray.y
        ray.vy = ray.vy + 520 * dt
        ray.x = ray.x + ray.vx * dt
        ray.y = ray.y + ray.vy * dt
        ray.angle = ray.angle + ray.spin * dt
        ray.life = ray.life - dt
        if ray.life <= 0 then
            table.remove(discardedRays, i)
        end
    end
end

function freeze.drawDiscarded(alpha, frustum, camera, screenWidth, screenHeight)
    alpha = alpha or 1
    for i = 1, #discardedRays do
        local ray = discardedRays[i]
        local drawX = lerp(ray.prevX, ray.x, alpha)
        local drawY = lerp(ray.prevY, ray.y, alpha)
        local visible = true
        if frustum and camera and screenWidth and screenHeight then
            visible = frustum:isCircleVisible(drawX, drawY, 40, camera, screenWidth, screenHeight)
        end
        if visible then
            local t = math.max(0, ray.life / ray.maxLife)
            local scale = freeze.gunScale * (0.15 + t * 0.85)
            love.graphics.setColor(1, 1, 1, t * t)
            love.graphics.draw(freeze.img, drawX, drawY, ray.angle, scale, scale, freeze.ox, freeze.oy)
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function freeze.discard(ball)
    if not ball.hasFreezeRay then
        return
    end
    freeze.spawnDiscarded(ball.x, ball.y, ball.vx, ball.vy, ball.shootAimAngle or math.atan2(ball.vy, ball.vx))
    ball.hasFreezeRay = false
    ball.freezeRayCharges = 0
end

function freeze.use(ball, nearby)
    if not ball.hasFreezeRay or ball.freezeRayCooldown > 0 or ball.frozenTimer > 0 then
        return
    end

    local hunterType = killerRules[ball.type]
    local freezeRadiusSq = 150 * 150
    local freezeDuration = 3.0
    local frozeCount = 0
    local beams = {}
    local aimX, aimY

    for i = 1, #nearby do
        local other = nearby[i]
        if other ~= ball and not other.dead and other.frozenTimer <= 0 and other.type == hunterType then
            local dx = other.x - ball.x
            local dy = other.y - ball.y
            if dx * dx + dy * dy < freezeRadiusSq then
                other.frozenTimer = freezeDuration
                other.vx = 0
                other.vy = 0
                frozeCount = frozeCount + 1
                beams[#beams + 1] = {x = other.x, y = other.y}
                if not aimX then
                    aimX, aimY = other.x, other.y
                end
            end
        end
    end

    if frozeCount > 0 then
        ball.freezeShootTimer = freeze.shootDuration
        ball.freezeBeams = beams
        ball.shootAimAngle = math.atan2(aimY - ball.y, aimX - ball.x)
        ball.freezeRayCharges = ball.freezeRayCharges - 1
        audio.playWorld("shoot", ball.x, ball.y)
        audio.playWorld("freeze", ball.x, ball.y, nil, nil, 0.85)
        if ball.freezeRayCharges <= 0 then
            freeze.discard(ball)
        end
    end

    ball.freezeRayCooldown = 1.0
end

function freeze.prepareDraw(ball, drawX, drawY, drawVx, drawVy)
    local aim = ball.shootAimAngle or math.atan2(drawVy, drawVx)
    ball._aim = aim
    local recoil = 0
    if ball.freezeShootTimer > 0 then
        recoil = -10 * (ball.freezeShootTimer / freeze.shootDuration)
    end
    local holdDist = 10 + recoil
    local holdX = drawX + math.cos(aim) * holdDist
    local holdY = drawY + math.sin(aim) * holdDist
    local barrel = (freeze.img:getWidth() - freeze.ox) * freeze.gunScale
    ball._muzzleX = holdX + math.cos(aim) * barrel
    ball._muzzleY = holdY + math.sin(aim) * barrel
    ball._holdX = holdX
    ball._holdY = holdY
end

function freeze.drawHeld(ball)
    if not ball._visible or not ball.hasFreezeRay then
        return
    end

    local pulse = 1
    if ball.freezeShootTimer > 0 then
        pulse = 1.15 + (ball.freezeShootTimer / freeze.shootDuration) * 0.2
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
        freeze.img,
        ball._holdX, ball._holdY, ball._aim,
        freeze.gunScale * pulse, freeze.gunScale * pulse,
        freeze.ox, freeze.oy
    )

    local pipX = ball._holdX + math.cos(ball._aim + 1.2) * 10
    local pipY = ball._holdY + math.sin(ball._aim + 1.2) * 10
    for i = 1, ball.freezeRayCharges do
        love.graphics.setColor(0.35, 0.9, 1, 0.85)
        love.graphics.circle("fill", pipX + (i - 1) * 5, pipY, 2.2)
    end
end

function freeze.drawBeams(ball)
    if not ball._visible or not ball.freezeBeams or ball.freezeShootTimer <= 0 then
        return
    end

    local t = ball.freezeShootTimer / freeze.shootDuration
    local muzzleX, muzzleY = ball._muzzleX, ball._muzzleY
    love.graphics.setLineWidth(2 + t * 5)

    for i = 1, #ball.freezeBeams do
        local target = ball.freezeBeams[i]
        love.graphics.setColor(0.55, 0.95, 1, 0.25 * t)
        love.graphics.setLineWidth(10 * t)
        love.graphics.line(muzzleX, muzzleY, target.x, target.y)
        love.graphics.setColor(0.75, 0.98, 1, 0.85 * t)
        love.graphics.setLineWidth(3 * t)
        love.graphics.line(muzzleX, muzzleY, target.x, target.y)

        for p = 1, 4 do
            local u = p / 5
            local px = muzzleX + (target.x - muzzleX) * u
            local py = muzzleY + (target.y - muzzleY) * u
            local radius = (2 + t * 5) * (0.4 + (p % 2) * 0.6)
            love.graphics.setColor(0.8, 1, 1, 0.7 * t)
            love.graphics.circle("fill", px, py, radius)
        end
    end

    love.graphics.setColor(0.85, 1, 1, t)
    love.graphics.circle("fill", muzzleX, muzzleY, 5 + t * 8)
    love.graphics.setColor(1, 1, 1, t)
    love.graphics.circle("fill", muzzleX, muzzleY, 2 + t * 3)
    love.graphics.setLineWidth(1)
end

return freeze
