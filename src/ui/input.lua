local M = {}
M.__index = M

function M.new(gamestate, mainCamera)
    local instance = setmetatable({}, M)
    instance.gamestate = gamestate
    instance.camera = mainCamera
    return instance
end

function M:handleKeyPress(key)
    if key == "escape" then
        return "menu"
    end
    if key == "r" then
        return "restart"
    end
    if key == "f" then
        if self.gamestate.timeScale == 1 then
            self.gamestate.timeScale = 4
        else
            self.gamestate.timeScale = 1
        end
        return "toggleSpeed"
    end
    return nil
end

return M
