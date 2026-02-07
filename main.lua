local ball = require "ball"
local slash = require "slash"
local balls = {}
local slashes = {}
local cellSize = 50 
local winner = nil
local gameTimer = 60 -- 60 second time limit
local timeOutWinner = nil
local timeScale = 1 -- Normal speed

local slashSound

function love.load()
    math.randomseed(os.time())
    local types = {"rock", "paper", "scissors"}
    local sW, sH = love.graphics.getDimensions()
    local margin = 50
    local spawns = 500

    slashSound = love.audio.newSource("assets/slash.wav", "static")
    for i = 1, spawns do
        table.insert(balls, ball:new(math.random(margin, sW - margin), math.random(margin, sH - margin), types[math.random(3)]))
    end
end

function love.update(dt)
    -- Apply the fast forward multiplier to dt
    local scaledDt = dt * timeScale

    if winner or timeOutWinner then return end

    -- 1. TEAM COUNT CHECK (For Auto-Restart)
    local counts = {rock = 0, paper = 0, scissors = 0}
    for _, b in ipairs(balls) do
        counts[b.type] = counts[b.type] + 1
    end

    -- Handle Timer
    gameTimer = gameTimer - scaledDt
    if gameTimer <= 0 then
        gameTimer = 0
        local counts = {rock = 0, paper = 0, scissors = 0}
        for _, b in ipairs(balls) do
            counts[b.type] = counts[b.type] + 1
        end
        
        -- Check for a 1 vs 1 vs 1 (or any equal) Tie
        if counts.rock == counts.paper and counts.paper == counts.scissors then
            timeOutWinner = "tie"
        -- Standard winning team logic (team with most prey)
        elseif counts.scissors >= counts.paper and counts.scissors >= counts.rock then
            timeOutWinner = "rock"
        elseif counts.paper >= counts.rock and counts.paper >= counts.scissors then
            timeOutWinner = "scissors"
        else
            timeOutWinner = "paper"
        end
    end

    -- Update Slashes
    for i = #slashes, 1, -1 do
        slashes[i]:update(scaledDt)
        if slashes[i].life <= 0 then table.remove(slashes, i) end
    end

    local grid = {}
    for _, b in ipairs(balls) do
        b:update(scaledDt, balls)
        local cx, cy = math.floor(b.x / cellSize), math.floor(b.y / cellSize)
        local slot = cx .. "x" .. cy
        if not grid[slot] then grid[slot] = {} end
        table.insert(grid[slot], b)
    end

    for _, b1 in ipairs(balls) do
        if not b1.dead then
            local cx, cy = math.floor(b1.x / cellSize), math.floor(b1.y / cellSize)
            for x = cx - 1, cx + 1 do
                for y = cy - 1, cy + 1 do
                    local slot = x .. "x" .. y
                    if grid[slot] then
                        for _, b2 in ipairs(grid[slot]) do
                            if b1 ~= b2 and not b2.dead then
                                local dx, dy = b2.x - b1.x, b2.y - b1.y
                                local distSq = dx*dx + dy*dy
                                
                                if distSq < (b1.size + b2.size)^2 then
                                    local rules = { rock = "scissors", scissors = "paper", paper = "rock" }
                                    local killer, victim = nil, nil
                                    
                                    if rules[b1.type] == b2.type then
                                        killer, victim = b1, b2
                                    elseif rules[b2.type] == b1.type then
                                        killer, victim = b2, b1
                                    end

                                    if killer and victim then
                                        -- 1. Get the direction the KILLER is already moving
                                        local speed = math.sqrt(killer.vx^2 + killer.vy^2)
                                        local dirX = killer.vx / speed
                                        local dirY = killer.vy / speed
                                        
                                        -- 2. ZIP THROUGH: Teleport the killer to the OTHER side of the victim
                                        -- We move the killer to the victim's spot, plus a dash distance
                                        local dashDist = 60 
                                        killer.x = victim.x + (dirX * dashDist)
                                        killer.y = victim.y + (dirY * dashDist)
                                        
                                        -- 3. BOOST SPEED: Maintain the same direction but much faster
                                        local zipSpeed = 1000 
                                        killer.vx = dirX * zipSpeed
                                        killer.vy = dirY * zipSpeed
                                        
                                        -- 4. KILL & SLASH
                                        victim.dead = true
                                        local slashAngle = math.atan2(dirY, dirX)
                                        table.insert(slashes, slash:new(victim.x, victim.y, slashAngle))

                                        -- Double Kill Logic
                                        killer.killCount = killer.killCount + 1
                                        killer.killTimer = 1.0 -- Must get another kill within 1 second
                                        
                                        if killer.killCount >= 2 then
                                            killer.showDoubleKill = 1.5 -- Show text for 1.5 seconds
                                            -- Optional: you could reset the count here or let it go to "Triple Kill" later
                                        end
                                        
                                        -- Play Sound
                                        local s = slashSound:clone()
                                        s:setPitch(math.random(0.9, 1.2))
                                        s:play()
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    for i = #balls, 1, -1 do
        if balls[i].dead then table.remove(balls, i) end
    end
end

function love.draw()
    local counts = {rock = 0, paper = 0, scissors = 0}

    for _, b in ipairs(balls) do 
        b:draw() 
        counts[b.type] = counts[b.type] + 1
    end

    -- 4. Draw Slashes
    for _, s in ipairs(slashes) do s:draw() end

    -- Draw UI Background
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 10, 10, 140, 115, 5) -- Made slightly taller
    
    -- Draw Stats
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("FPS: " .. love.timer.getFPS(), 20, 20)
    love.graphics.print("TIME: " .. math.ceil(gameTimer), 20, 40)
    love.graphics.print("Rock: " .. counts.rock, 20, 60)
    love.graphics.print("Paper: " .. counts.paper, 20, 80)
    love.graphics.print("Scissors: " .. counts.scissors, 20, 100)

    -- Winner Logic
    local activeTypes = 0
    local lastType = ""
    for bType, count in pairs(counts) do
        if count > 0 then
            activeTypes = activeTypes + 1
            lastType = bType
        end
    end

    if activeTypes == 1 and not winner then
        winner = lastType
    end

    -- Show status in the UI
    love.graphics.setColor(1, 1, 1)
    if timeScale > 1 then
        love.graphics.print("FAST FORWARD: " .. timeScale .. "x", 20, 120)
    end

    -- Handle Winner Display (Both types: Extinction or Timeout)
    local finalWinner = winner or timeOutWinner
    if finalWinner then
        local screenW = love.graphics.getWidth()
        local screenH = love.graphics.getHeight()
        
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 0, 0, screenW, screenH)
        
        love.graphics.setColor(1, 1, 0)
        local msg
        if finalWinner == "tie" then
            msg = "STALEMATE! IT'S A TIE!"
        else
            msg = string.upper(finalWinner) .. " WINS BY " .. (winner and "DOMINATION!" or "TIME LIMIT!")
        end
        
        -- Center text properly
        love.graphics.printf(msg, 0, screenH/2 - 20, screenW/2, "center", 0, 2, 2)
    end
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
    if key == "r" then love.event.quit("restart") end
    -- Press 'F' to toggle 4x speed
    if key == "f" then
        if timeScale == 1 then
            timeScale = 4 
        else
            timeScale = 1
        end
    end
end