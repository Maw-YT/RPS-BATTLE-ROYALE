local M = {}
M.__index = M

function M.new()
    return setmetatable({}, M)
end

function M:countEntities(balls)
    local counts = { rock = 0, paper = 0, scissors = 0 }
    for _, b in ipairs(balls) do
        counts[b.type] = counts[b.type] + 1
    end
    return counts
end

function M:calculateScores(counts)
    return {
        rock     = counts.rock > 0 and (counts.scissors + 1) / (counts.paper + 1) or 0,
        paper    = counts.paper > 0 and (counts.rock + 1) / (counts.scissors + 1) or 0,
        scissors = counts.scissors > 0 and (counts.paper + 1) / (counts.rock + 1) or 0
    }
end

function M:determineTimeOutWinner(counts)
    local scores = self:calculateScores(counts)
    local maxScore = math.max(scores.rock, scores.paper, scores.scissors)
    if maxScore == 0 then
        return "tie"
    elseif scores.rock == maxScore then
        return "rock"
    elseif scores.paper == maxScore then
        return "paper"
    end
    return "scissors"
end

function M:checkExtinctionWinner(counts)
    local activeTypes = 0
    local lastType = ""
    for bType, count in pairs(counts) do
        if count > 0 then
            activeTypes = activeTypes + 1
            lastType = bType
        end
    end
    if activeTypes == 1 then
        return lastType
    end
    return nil
end

return M
