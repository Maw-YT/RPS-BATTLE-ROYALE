local M = {}

function M.generateHouse(tiles)
    local houseWidth = math.random(5, 9)
    local houseHeight = math.random(5, 9)
    local startX = math.random(3, tiles.gridWidth - houseWidth - 3)
    local startY = math.random(3, tiles.gridHeight - houseHeight - 3)

    for dx = 0, houseWidth - 1 do
        for dy = 0, houseHeight - 1 do
            if tiles.grid[startX + dx][startY + dy] ~= tiles.EMPTY then
                return
            end
        end
    end

    for dx = 0, houseWidth - 1 do
        tiles.grid[startX + dx][startY] = tiles.WALL
        tiles.grid[startX + dx][startY + houseHeight - 1] = tiles.WALL
    end
    for dy = 0, houseHeight - 1 do
        tiles.grid[startX][startY + dy] = tiles.WALL
        tiles.grid[startX + houseWidth - 1][startY + dy] = tiles.WALL
    end

    local doorSide = math.random(4)
    local doorPos
    if doorSide == 1 then
        doorPos = math.random(1, houseWidth - 2)
        tiles.grid[startX + doorPos][startY] = tiles.EMPTY
        tiles.grid[startX + doorPos + 1][startY] = tiles.EMPTY
    elseif doorSide == 2 then
        doorPos = math.random(1, houseHeight - 2)
        tiles.grid[startX + houseWidth - 1][startY + doorPos] = tiles.EMPTY
        tiles.grid[startX + houseWidth - 1][startY + doorPos + 1] = tiles.EMPTY
    elseif doorSide == 3 then
        doorPos = math.random(1, houseWidth - 2)
        tiles.grid[startX + doorPos][startY + houseHeight - 1] = tiles.EMPTY
        tiles.grid[startX + doorPos + 1][startY + houseHeight - 1] = tiles.EMPTY
    else
        doorPos = math.random(1, houseHeight - 2)
        tiles.grid[startX][startY + doorPos] = tiles.EMPTY
        tiles.grid[startX][startY + doorPos + 1] = tiles.EMPTY
    end

    local chestX = startX + math.floor(houseWidth / 2)
    local chestY = startY + math.floor(houseHeight / 2)
    tiles.grid[chestX][chestY] = tiles.CHEST
    table.insert(tiles.chests, {x = chestX, y = chestY, cellSize = tiles.cellSize})
end

function M.generate(tiles)
    for x = 1, tiles.gridWidth do
        tiles.grid[x] = {}
        for y = 1, tiles.gridHeight do
            tiles.grid[x][y] = tiles.EMPTY
        end
    end

    for _ = 1, 12 do
        M.generateHouse(tiles)
    end

    for _ = 1, 15 do
        local cx = math.random(5, tiles.gridWidth - 5)
        local cy = math.random(5, tiles.gridHeight - 5)
        local clusterSize = math.random(2, 4)
        for _ = 1, clusterSize do
            local tx = cx + math.random(-2, 2)
            local ty = cy + math.random(-2, 2)
            if tx >= 1 and tx <= tiles.gridWidth and ty >= 1 and ty <= tiles.gridHeight then
                if tiles.grid[tx][ty] == tiles.EMPTY then
                    tiles.grid[tx][ty] = tiles.WALL
                end
            end
        end
    end

    for _ = 1, 8 do
        local isHorizontal = math.random() > 0.5
        local length = math.random(5, 12)
        local startX = math.random(1, tiles.gridWidth - length)
        local startY = math.random(1, tiles.gridHeight)

        if isHorizontal then
            for dx = 0, length - 1 do
                local tx = startX + dx
                if tx <= tiles.gridWidth and tiles.grid[tx][startY] == tiles.EMPTY then
                    tiles.grid[tx][startY] = tiles.WALL
                end
            end
        else
            local y = math.random(1, tiles.gridHeight - length)
            for dy = 0, length - 1 do
                local ty = y + dy
                if ty <= tiles.gridHeight and tiles.grid[startX][ty] == tiles.EMPTY then
                    tiles.grid[startX][ty] = tiles.WALL
                end
            end
        end
    end
end

return M
