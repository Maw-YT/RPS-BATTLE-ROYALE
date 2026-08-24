local M = {}
M.__index = M

function M.new()
    return setmetatable({}, M)
end

function M:drawStats(gameTimer, counts, timeScale, settings)
    if settings and not settings.showHud then
        if settings.showFps then
            love.graphics.setColor(1, 1, 1, 0.8)
            love.graphics.print("FPS: " .. love.timer.getFPS(), 20, 20)
        end
        return
    end

    local extra = 0
    if settings and settings.debug then
        extra = 50
    end
    if settings and not settings.showFps then
        extra = extra - 16
    end

    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 10, 10, 150, 115 + extra, 5)

    local y = 20
    love.graphics.setColor(1, 1, 1)
    if not settings or settings.showFps then
        love.graphics.print("FPS: " .. love.timer.getFPS(), 20, y)
        y = y + 20
    end
    love.graphics.print("TIME: " .. math.ceil(gameTimer), 20, y)
    love.graphics.print("Rock: " .. counts.rock, 20, y + 20)
    love.graphics.print("Paper: " .. counts.paper, 20, y + 40)
    love.graphics.print("Scissors: " .. counts.scissors, 20, y + 60)

    if timeScale > 1 then
        love.graphics.print("FAST FORWARD: " .. timeScale .. "x", 20, y + 80)
    end

    if settings and settings.debug then
        love.graphics.setColor(1, 0.85, 0.2)
        love.graphics.print("DEBUG ON", 20, y + 100)
        local total = counts.rock + counts.paper + counts.scissors
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Alive: " .. total, 20, y + 115)
        love.graphics.print("VSync: " .. (settings.vsync and "ON" or "OFF"), 20, y + 130)
    end
end

function M:drawWinnerScreen(winner, isExtinction)
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    love.graphics.setColor(1, 1, 0)
    local msg
    if winner == "tie" then
        msg = "STALEMATE! IT'S A TIE!"
    else
        msg = string.upper(winner) .. " WINS BY " .. (isExtinction and "DOMINATION!" or "TIME LIMIT!")
    end

    love.graphics.printf(msg, 0, screenH / 2 - 20, screenW / 2, "center", 0, 2, 2)

    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.printf("R to restart   ·   Esc for menu", 0, screenH / 2 + 50, screenW, "center")
end

return M
