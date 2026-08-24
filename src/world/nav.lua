local M = {}
M.__index = M

function M.new(cellSize, screenWidth, screenHeight, tilegrid)
    local instance = setmetatable({}, M)
    instance.cellSize = cellSize or 100
    instance.screenWidth = screenWidth
    instance.screenHeight = screenHeight
    instance.gridWidth = math.ceil(screenWidth / cellSize)
    instance.gridHeight = math.ceil(screenHeight / cellSize)
    instance.grid = {}
    instance.tilegrid = tilegrid
    instance:initGrid()
    return instance
end

function M:initGrid()
    for x = 1, self.gridWidth do
        self.grid[x] = {}
        for y = 1, self.gridHeight do
            self.grid[x][y] = { rock = 0, paper = 0, scissors = 0 }
        end
    end
end

function M:clear()
    for x = 1, self.gridWidth do
        local col = self.grid[x]
        for y = 1, self.gridHeight do
            local cell = col[y]
            cell.rock = 0
            cell.paper = 0
            cell.scissors = 0
        end
    end
end

function M:cellToScreen(cx, cy)
    return (cx - 0.5) * self.cellSize, (cy - 0.5) * self.cellSize
end

function M:screenToCell(x, y)
    return math.floor(x / self.cellSize) + 1, math.floor(y / self.cellSize) + 1
end

function M:update(balls)
    self:clear()
    for i = 1, #balls do
        local b = balls[i]
        if not b.dead then
            local cx, cy = self:screenToCell(b.x, b.y)
            if cx >= 1 and cx <= self.gridWidth and cy >= 1 and cy <= self.gridHeight then
                local cell = self.grid[cx][cy]
                cell[b.type] = cell[b.type] + 1
            end
        end
    end
end

function M:findNearestChest(myX, myY)
    if not self.tilegrid or not self.tilegrid.chests or #self.tilegrid.chests == 0 then
        return nil, nil
    end

    local nearestX, nearestY
    local nearestDistSq = math.huge
    local tileSize = self.tilegrid.cellSize
    local chests = self.tilegrid.chests

    for i = 1, #chests do
        local chest = chests[i]
        local chestX = (chest.x - 0.5) * tileSize
        local chestY = (chest.y - 0.5) * tileSize
        local dx = chestX - myX
        local dy = chestY - myY
        local distSq = dx * dx + dy * dy
        if distSq < nearestDistSq then
            nearestDistSq = distSq
            nearestX = chestX
            nearestY = chestY
        end
    end

    return nearestX, nearestY
end

function M:getBestDirection(cx, cy, targetType, hunterType, myX, myY, hasFreezeRay)
    local dirX, dirY = 0, 0
    local bestPreyX, bestPreyY
    local bestPreyDistSq = math.huge
    local bestHunterX, bestHunterY
    local bestHunterDistSq = math.huge
    local searchRadius = 3

    for dx = -searchRadius, searchRadius do
        for dy = -searchRadius, searchRadius do
            local nx, ny = cx + dx, cy + dy
            if nx >= 1 and nx <= self.gridWidth and ny >= 1 and ny <= self.gridHeight then
                local cell = self.grid[nx][ny]
                local cellDistSq = dx * dx + dy * dy

                if cell[targetType] > 0 and cellDistSq < bestPreyDistSq then
                    bestPreyDistSq = cellDistSq
                    bestPreyX, bestPreyY = nx, ny
                end

                if cell[hunterType] > 0 and cellDistSq < bestHunterDistSq then
                    bestHunterDistSq = cellDistSq
                    bestHunterX, bestHunterY = nx, ny
                end
            end
        end
    end

    if bestPreyX then
        local targetX = (bestPreyX - 0.5) * self.cellSize
        local targetY = (bestPreyY - 0.5) * self.cellSize
        local dx = targetX - myX
        local dy = targetY - myY
        local len = math.sqrt(dx * dx + dy * dy)
        if len > 0 then
            dirX = dirX + (dx / len) * 0.6
            dirY = dirY + (dy / len) * 0.6
        end
    end

    if bestHunterX and bestHunterDistSq < 9 then
        local hunterX = (bestHunterX - 0.5) * self.cellSize
        local hunterY = (bestHunterY - 0.5) * self.cellSize
        local dx = myX - hunterX
        local dy = myY - hunterY
        local len = math.sqrt(dx * dx + dy * dy)
        if len > 0 then
            local fleeStrength = math.max(0, 1 - math.sqrt(bestHunterDistSq) / 3)
            dirX = dirX + (dx / len) * fleeStrength * 0.4
            dirY = dirY + (dy / len) * fleeStrength * 0.4
        end
    end

    if not hasFreezeRay and not bestPreyX and not bestHunterX then
        local chestX, chestY = self:findNearestChest(myX, myY)
        if chestX then
            local dx = chestX - myX
            local dy = chestY - myY
            local len = math.sqrt(dx * dx + dy * dy)
            if len > 0 then
                dirX = dirX + (dx / len) * 0.5
                dirY = dirY + (dy / len) * 0.5
            end
        end
    end

    local tilegrid = self.tilegrid
    if tilegrid then
        local cs = tilegrid.cellSize
        local tx = math.floor(myX / cs) + 1
        local ty = math.floor(myY / cs) + 1
        for dx = -1, 1 do
            for dy = -1, 1 do
                if dx ~= 0 or dy ~= 0 then
                    local nx, ny = tx + dx, ty + dy
                    if nx >= 1 and nx <= tilegrid.gridWidth and ny >= 1 and ny <= tilegrid.gridHeight then
                        if tilegrid.grid[nx][ny] == tilegrid.WALL then
                            dirX = dirX - dx * 0.8
                            dirY = dirY - dy * 0.8
                        end
                    end
                end
            end
        end
    end

    local len = math.sqrt(dirX * dirX + dirY * dirY)
    if len > 0 then
        return dirX / len, dirY / len
    end
    return 0, 0
end

return M
