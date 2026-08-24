local constants = require "src.core.constants"

local spawn = {}

function spawn.balls(balls, ball, count, worldWidth, worldHeight, tileGrid)
    local types = {"rock", "paper", "scissors"}
    local spawned = 0
    local attempts = 0
    local maxAttempts = count * 50
    local ballSize = 20

    while spawned < count and attempts < maxAttempts do
        local x = math.random(constants.margin, worldWidth - constants.margin)
        local y = math.random(constants.margin, worldHeight - constants.margin)
        local valid = true

        if tileGrid then
            local checkPoints = {
                {x, y},
                {x - ballSize, y},
                {x + ballSize, y},
                {x, y - ballSize},
                {x, y + ballSize},
                {x - ballSize, y - ballSize},
                {x + ballSize, y - ballSize},
                {x - ballSize, y + ballSize},
                {x + ballSize, y + ballSize}
            }

            for _, point in ipairs(checkPoints) do
                if not tileGrid:isWalkable(point[1], point[2]) then
                    valid = false
                    break
                end
            end

            if valid then
                local openDirections = 0
                local checkDist = 100
                local directions = {
                    {dx = 1, dy = 0},
                    {dx = -1, dy = 0},
                    {dx = 0, dy = 1},
                    {dx = 0, dy = -1}
                }

                for _, dir in ipairs(directions) do
                    local canMove = true
                    for step = 1, checkDist, 20 do
                        local checkX = x + dir.dx * step
                        local checkY = y + dir.dy * step
                        if not tileGrid:isWalkable(checkX, checkY) then
                            canMove = false
                            break
                        end
                    end
                    if canMove then
                        openDirections = openDirections + 1
                    end
                end

                if openDirections < 2 then
                    valid = false
                end
            end
        end

        if valid then
            table.insert(balls, ball:new(x, y, types[math.random(3)]))
            spawned = spawned + 1
        end
        attempts = attempts + 1
    end

    if spawned < count then
        print("Warning: Only spawned " .. spawned .. " entities out of " .. count .. " requested")
    end
end

return spawn
