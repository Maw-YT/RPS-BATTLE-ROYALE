local constants = require "src.core.constants"
local settings = require "src.core.settings"
local houses = require "src.world.houses"

local M = {}
M.__index = M

M.EMPTY = 0
M.WALL = 1
M.CHEST = 2

local WALL_KEY = 8192

local function wallKey(cx, cy)
    return cx * WALL_KEY + cy
end

function M.new(cellSize, worldWidth, worldHeight)
    local instance = setmetatable({}, M)
    instance.cellSize = cellSize or 50
    instance.worldWidth = worldWidth
    instance.worldHeight = worldHeight
    instance.gridWidth = math.ceil(worldWidth / cellSize)
    instance.gridHeight = math.ceil(worldHeight / cellSize)
    instance.grid = {}
    instance.chests = {}
    instance.walls = {}
    instance.wallLookup = {}
    instance.chestImage = love.graphics.newImage("assets/chest.png")
    houses.generate(instance)
    instance:indexWalls()
    instance:createWallBatch()
    return instance
end

function M:indexWalls()
    self.walls = {}
    self.wallLookup = {}
    local maxHp = constants.wallMaxHp
    for x = 1, self.gridWidth do
        local col = self.grid[x]
        for y = 1, self.gridHeight do
            if col[y] == self.WALL then
                local wall = {
                    x = x,
                    y = y,
                    hp = maxHp,
                    maxHp = maxHp,
                    flash = 0,
                    cooldown = 0
                }
                self.walls[#self.walls + 1] = wall
                self.wallLookup[wallKey(x, y)] = #self.walls
            end
        end
    end
end

function M:createWallBatch()
    local data = love.image.newImageData(1, 1)
    data:setPixel(0, 0, 1, 1, 1, 1)
    self.wallImage = love.graphics.newImage(data)
    self.wallImage:setFilter("nearest", "nearest")
    self.wallBatch = love.graphics.newSpriteBatch(self.wallImage, math.max(64, #self.walls + 16), "stream")
end

function M:isWalkable(x, y)
    local cx = math.floor(x / self.cellSize) + 1
    local cy = math.floor(y / self.cellSize) + 1
    if cx < 1 or cx > self.gridWidth or cy < 1 or cy > self.gridHeight then
        return false
    end
    local tile = self.grid[cx][cy]
    return tile == self.EMPTY or tile == self.CHEST
end

function M:isChest(x, y)
    local cx = math.floor(x / self.cellSize) + 1
    local cy = math.floor(y / self.cellSize) + 1
    if cx < 1 or cx > self.gridWidth or cy < 1 or cy > self.gridHeight then
        return false
    end
    return self.grid[cx][cy] == self.CHEST
end

function M:removeChest(x, y)
    local cx = math.floor(x / self.cellSize) + 1
    local cy = math.floor(y / self.cellSize) + 1
    if cx >= 1 and cx <= self.gridWidth and cy >= 1 and cy <= self.gridHeight then
        if self.grid[cx][cy] == self.CHEST then
            self.grid[cx][cy] = self.EMPTY
            for i, chest in ipairs(self.chests) do
                if chest.x == cx and chest.y == cy then
                    table.remove(self.chests, i)
                    break
                end
            end
            return true
        end
    end
    return false
end

function M:update(dt)
    for i = 1, #self.walls do
        local wall = self.walls[i]
        if wall.flash > 0 then
            wall.flash = wall.flash - dt
        end
        if wall.cooldown > 0 then
            wall.cooldown = wall.cooldown - dt
        end
    end
end

function M:findWallAt(worldX, worldY, size)
    size = size or 0
    local points = {
        worldX, worldY,
        worldX - size, worldY,
        worldX + size, worldY,
        worldX, worldY - size,
        worldX, worldY + size,
        worldX - size, worldY - size,
        worldX + size, worldY - size,
        worldX - size, worldY + size,
        worldX + size, worldY + size
    }
    for i = 1, #points, 2 do
        local cx = math.floor(points[i] / self.cellSize) + 1
        local cy = math.floor(points[i + 1] / self.cellSize) + 1
        if cx >= 1 and cx <= self.gridWidth and cy >= 1 and cy <= self.gridHeight then
            if self.grid[cx][cy] == self.WALL then
                return cx, cy
            end
        end
    end
    return nil
end

function M:damageWall(cx, cy, amount)
    local idx = self.wallLookup[wallKey(cx, cy)]
    if not idx then
        return false
    end
    local wall = self.walls[idx]
    if wall.cooldown > 0 then
        return false
    end

    wall.hp = wall.hp - (amount or 1)
    wall.flash = 0.12
    wall.cooldown = constants.wallHitCooldown

    if wall.hp <= 0 then
        self.grid[cx][cy] = self.EMPTY
        local last = self.walls[#self.walls]
        self.walls[idx] = last
        self.walls[#self.walls] = nil
        self.wallLookup[wallKey(cx, cy)] = nil
        if last and (last.x ~= cx or last.y ~= cy) then
            self.wallLookup[wallKey(last.x, last.y)] = idx
        end
        return true
    end
    return false
end

function M:damageWallAt(worldX, worldY, amount, size)
    local cx, cy = self:findWallAt(worldX, worldY, size)
    if cx then
        return self:damageWall(cx, cy, amount)
    end
    return false
end

function M:cellToScreen(cx, cy)
    return (cx - 1) * self.cellSize, (cy - 1) * self.cellSize
end

function M:screenToCell(x, y)
    return math.floor(x / self.cellSize) + 1, math.floor(y / self.cellSize) + 1
end

function M:draw(frustum, camera, screenWidth, screenHeight)
    if self.wallBatch then
        self.wallBatch:clear()
        local debugHp = settings.debug
        for i = 1, #self.walls do
            local wall = self.walls[i]
            local sx, sy = self:cellToScreen(wall.x, wall.y)
            local t = wall.hp / wall.maxHp
            local r, g, b = 0.3 + (1 - t) * 0.45, 0.3 * t + 0.08, 0.35 * t
            if wall.flash > 0 and not settings.reduceFlash then
                r, g, b = 1, 0.72, 0.45
            end
            self.wallBatch:setColor(r, g, b, 1)
            self.wallBatch:add(sx, sy, 0, self.cellSize, self.cellSize)
        end
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.wallBatch)

        if debugHp then
            for i = 1, #self.walls do
                local wall = self.walls[i]
                if wall.hp < wall.maxHp then
                    local sx, sy = self:cellToScreen(wall.x, wall.y)
                    if not frustum or not camera or frustum:isRectVisible(sx, sy, self.cellSize, self.cellSize, camera, screenWidth, screenHeight) then
                        love.graphics.setColor(1, 1, 1, 0.9)
                        love.graphics.print(wall.hp, sx + 6, sy + 6)
                    end
                end
            end
        end
    end

    local chests = self.chests
    local img = self.chestImage
    local scale = (self.cellSize * 1.4) / img:getWidth()
    for i = 1, #chests do
        local chest = chests[i]
        local sx, sy = self:cellToScreen(chest.x, chest.y)
        if not frustum or not camera or frustum:isRectVisible(sx, sy, self.cellSize, self.cellSize, camera, screenWidth, screenHeight) then
            local cx = sx + self.cellSize / 2
            local cy = sy + self.cellSize / 2
            local glow = 0.35 + math.sin(love.timer.getTime() * 3) * 0.15
            love.graphics.setColor(1, 0.85, 0.2, glow)
            love.graphics.circle("fill", cx, cy, self.cellSize * 0.42)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(img, cx, cy, 0, scale, scale, img:getWidth() / 2, img:getHeight() / 2)
        end
    end
end

return M
