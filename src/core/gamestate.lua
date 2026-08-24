local constants = require "src.core.constants"

local M = {}
M.__index = M

function M.new()
    local instance = setmetatable({}, M)
    instance.scene = "main_menu"
    instance.mode = nil
    instance.winner = nil
    instance.gameTimer = constants.gameTimer
    instance.timeOutWinner = nil
    instance.timeScale = 1
    return instance
end

function M:reset()
    self.winner = nil
    self.gameTimer = constants.gameTimer
    self.timeOutWinner = nil
    self.timeScale = 1
end

function M:isGameOver()
    return self.winner or self.timeOutWinner
end

function M:getFinalWinner()
    return self.winner or self.timeOutWinner
end

return M
