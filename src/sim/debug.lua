local constants = require "src.core.constants"
local settings = require "src.core.settings"

local debug = {}

function debug.drawWorld(navGrid, currentMode, frustumCuller, mainCamera, worldWidth, worldHeight, sW, sH)
    if navGrid then
        local cs = navGrid.cellSize
        local startX, startY, endX, endY
        if currentMode.useCamera then
            local bounds = frustumCuller:getVisibleBounds(mainCamera, sW, sH, cs)
            startX = math.max(1, math.floor(bounds.left / cs) + 1)
            startY = math.max(1, math.floor(bounds.top / cs) + 1)
            endX = math.min(navGrid.gridWidth, math.ceil(bounds.right / cs) + 1)
            endY = math.min(navGrid.gridHeight, math.ceil(bounds.bottom / cs) + 1)
        else
            startX, startY = 1, 1
            endX, endY = navGrid.gridWidth, navGrid.gridHeight
        end
        for cx = startX, endX do
            local col = navGrid.grid[cx]
            if col then
                for cy = startY, endY do
                    local cell = col[cy]
                    if cell then
                        local total = cell.rock + cell.paper + cell.scissors
                        if total > 0 then
                            local sx, sy = navGrid:cellToScreen(cx, cy)
                            sx = sx - cs / 2
                            sy = sy - cs / 2
                            love.graphics.setColor(1, 1, 0, math.min(0.28, 0.06 + total * 0.02))
                            love.graphics.rectangle("fill", sx, sy, cs, cs)
                            love.graphics.setColor(1, 1, 1, 0.6)
                            love.graphics.print(total, sx + 4, sy + 4)
                        end
                    end
                end
            end
        end
    end

    local cell = constants.cellSize
    local left, top, right, bottom = 0, 0, worldWidth, worldHeight
    if currentMode.useCamera then
        local bounds = frustumCuller:getVisibleBounds(mainCamera, sW, sH, cell)
        left, top, right, bottom = bounds.left, bounds.top, bounds.right, bounds.bottom
    end
    love.graphics.setColor(0, 1, 1, 0.12)
    love.graphics.setLineWidth(1)
    for x = math.floor(left / cell) * cell, right, cell do
        love.graphics.line(x, math.max(0, top), x, math.min(worldHeight, bottom))
    end
    for y = math.floor(top / cell) * cell, bottom, cell do
        love.graphics.line(math.max(0, left), y, math.min(worldWidth, right), y)
    end
end

function debug.drawGrid(currentMode, frustumCuller, mainCamera, worldWidth, worldHeight, sW, sH)
    if not settings.showGrid then
        return
    end
    love.graphics.setColor(0.1, 0.1, 0.1)
    if currentMode.useCamera then
        local bounds = frustumCuller:getVisibleBounds(mainCamera, sW, sH, 200)
        for x = math.floor(bounds.left / 200) * 200, bounds.right, 200 do
            love.graphics.line(x, math.max(0, bounds.top), x, math.min(worldHeight, bounds.bottom))
        end
        for y = math.floor(bounds.top / 200) * 200, bounds.bottom, 200 do
            love.graphics.line(math.max(0, bounds.left), y, math.min(worldWidth, bounds.right), y)
        end
    else
        for x = 0, worldWidth, 200 do
            love.graphics.line(x, 0, x, worldHeight)
        end
        for y = 0, worldHeight, 200 do
            love.graphics.line(0, y, worldWidth, y)
        end
    end
end

return debug
