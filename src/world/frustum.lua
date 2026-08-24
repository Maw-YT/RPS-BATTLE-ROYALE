local M = {}
M.__index = M

function M.new()
    return setmetatable({}, M)
end

function M:isPointVisible(x, y, camera, screenWidth, screenHeight, margin)
    margin = margin or 0
    local left = camera.x - margin
    local top = camera.y - margin
    local right = camera.x + screenWidth / camera.scale + margin
    local bottom = camera.y + screenHeight / camera.scale + margin
    return x >= left and x <= right and y >= top and y <= bottom
end

function M:isCircleVisible(x, y, radius, camera, screenWidth, screenHeight, margin)
    margin = margin or 0
    local left = camera.x - margin - radius
    local top = camera.y - margin - radius
    local right = camera.x + screenWidth / camera.scale + margin + radius
    local bottom = camera.y + screenHeight / camera.scale + margin + radius
    return not (x < left or x > right or y < top or y > bottom)
end

function M:isRectVisible(x, y, width, height, camera, screenWidth, screenHeight, margin)
    margin = margin or 0
    local left = camera.x - margin
    local top = camera.y - margin
    local right = camera.x + screenWidth / camera.scale + margin
    local bottom = camera.y + screenHeight / camera.scale + margin
    return not (x + width < left or x > right or y + height < top or y > bottom)
end

function M:getVisibleBounds(camera, screenWidth, screenHeight, margin)
    margin = margin or 0
    return {
        left = camera.x - margin,
        top = camera.y - margin,
        right = camera.x + screenWidth / camera.scale + margin,
        bottom = camera.y + screenHeight / camera.scale + margin
    }
end

function M:isAudible(x, y, camera, screenWidth, screenHeight, soundRange)
    soundRange = soundRange or 200
    local left = camera.x - soundRange
    local top = camera.y - soundRange
    local right = camera.x + screenWidth / camera.scale + soundRange
    local bottom = camera.y + screenHeight / camera.scale + soundRange
    return not (x < left or x > right or y < top or y > bottom)
end

return M
