local M = {}

M.cellSize = 50
M.gameTimer = 120
M.margin = 50
M.spawns = 2000

M.worldWidth = 16000
M.worldHeight = 12000

M.dashDist = 60
M.zipSpeed = 1000
M.normalSpeed = 120
M.physicsTPS = 25
M.physicsDt = 1 / 25
M.physicsMaxSteps = 2
M.wallMaxHp = 3
M.wallHitCooldown = 0.15

M.uiWidth = 140
M.uiHeight = 115

M.modes = {
    fortnite = {
        id = "fortnite",
        name = "Fortnite Mode",
        useTiles = true,
        useCamera = true,
        useFreezeRays = true,
        spawns = 2000,
        worldWidth = 16000,
        worldHeight = 12000
    },
    simple = {
        id = "simple",
        name = "Simple Mode",
        useTiles = false,
        useCamera = false,
        useFreezeRays = false,
        spawns = 300,
        worldWidth = nil,
        worldHeight = nil
    }
}

return M
