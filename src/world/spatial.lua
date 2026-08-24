local M = {}
M.__index = M

local KEY_STRIDE = 8192

function M.new(cellSize)
    local instance = setmetatable({}, M)
    instance.cellSize = cellSize or 50
    instance.cells = {}
    instance.pool = {}
    return instance
end

function M:clear()
    for key, cell in pairs(self.cells) do
        for i = #cell, 1, -1 do
            cell[i] = nil
        end
        self.pool[#self.pool + 1] = cell
        self.cells[key] = nil
    end
end

function M:insert(entity)
    local cx = math.floor(entity.x / self.cellSize)
    local cy = math.floor(entity.y / self.cellSize)
    local key = cx * KEY_STRIDE + cy
    local cell = self.cells[key]
    if not cell then
        local poolSize = #self.pool
        if poolSize > 0 then
            cell = self.pool[poolSize]
            self.pool[poolSize] = nil
        else
            cell = {}
        end
        self.cells[key] = cell
    end
    cell[#cell + 1] = entity
end

function M:getNearbyInRange(x, y, range, out)
    out = out or {}
    for i = #out, 1, -1 do
        out[i] = nil
    end

    local radius = math.ceil(range / self.cellSize)
    local cx = math.floor(x / self.cellSize)
    local cy = math.floor(y / self.cellSize)
    local n = 0

    for dx = -radius, radius do
        for dy = -radius, radius do
            local cell = self.cells[(cx + dx) * KEY_STRIDE + (cy + dy)]
            if cell then
                for i = 1, #cell do
                    n = n + 1
                    out[n] = cell[i]
                end
            end
        end
    end

    return out
end

function M:getNearbyEntities(x, y, out)
    return self:getNearbyInRange(x, y, self.cellSize, out)
end

return M
