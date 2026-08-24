local ball = require "src.entities.ball"
local slash = require "src.entities.slash"
local constants = require "src.core.constants"
local spatial = require "src.world.spatial"
local nav = require "src.world.nav"
local tiles = require "src.world.tiles"
local collision = require "src.combat.collision"
local scoring = require "src.combat.scoring"
local hud = require "src.ui.hud"
local input = require "src.ui.input"
local camera = require "src.world.camera"
local frustum = require "src.world.frustum"
local settings = require "src.core.settings"
local audio = require "src.audio"
local spawn = require "src.sim.spawn"
local debug = require "src.sim.debug"

local session = {
    balls = {},
    slashes = {},
    spatialGrid = nil,
    navGrid = nil,
    tileGrid = nil,
    collisionSystem = nil,
    scoringSystem = nil,
    hudSystem = nil,
    inputHandler = nil,
    gameState = nil,
    mainCamera = nil,
    frustumCuller = nil,
    worldWidth = 0,
    worldHeight = 0,
    currentMode = nil,
    physicsAccumulator = 0,
    interpAlpha = 1
}

function session.bind(gameState)
    session.gameState = gameState
    session.scoringSystem = scoring.new()
    session.hudSystem = hud.new()
    session.frustumCuller = frustum.new()
end

function session.returnToMenu(menuSystem)
    session.balls = {}
    session.slashes = {}
    session.tileGrid = nil
    session.navGrid = nil
    session.currentMode = nil
    session.physicsAccumulator = 0
    session.interpAlpha = 1
    ball.clearEffects()
    audio.playMusic("menu")
    audio.setWorld(nil, nil)
    session.gameState.scene = "main_menu"
    session.gameState.mode = nil
    session.gameState:reset()
    menuSystem.selected = 1
    menuSystem.hover = nil
end

function session.startGame(modeId)
    local config = constants.modes[modeId]
    local sW, sH = love.graphics.getDimensions()
    local gameState = session.gameState

    session.currentMode = config
    gameState.mode = modeId
    gameState.scene = "playing"
    gameState:reset()

    session.worldWidth = config.worldWidth or sW
    session.worldHeight = config.worldHeight or sH
    session.balls = {}
    session.slashes = {}
    session.physicsAccumulator = 0
    session.interpAlpha = 1
    ball.clearEffects()

    session.spatialGrid = spatial.new(constants.cellSize)

    if config.useTiles then
        session.tileGrid = tiles.new(50, session.worldWidth, session.worldHeight)
    else
        session.tileGrid = nil
    end

    session.navGrid = nav.new(100, session.worldWidth, session.worldHeight, session.tileGrid)
    session.mainCamera = camera.new()

    if config.useCamera then
        session.mainCamera.x = session.worldWidth / 2 - sW / 2
        session.mainCamera.y = session.worldHeight / 2 - sH / 2
    else
        session.mainCamera.x = 0
        session.mainCamera.y = 0
        session.mainCamera.scale = 1
        session.mainCamera.targetScale = 1
    end

    session.collisionSystem = collision.new(session.spatialGrid, session.frustumCuller, session.mainCamera)
    session.inputHandler = input.new(gameState, session.mainCamera)
    audio.setWorld(session.frustumCuller, session.mainCamera)

    spawn.balls(session.balls, ball, config.spawns, session.worldWidth, session.worldHeight, session.tileGrid)
    audio.playMusic("battle")
end

function session.physicsStep(dt)
    local gameState = session.gameState
    local balls = session.balls
    local slashes = session.slashes
    local tileGrid = session.tileGrid

    gameState.gameTimer = gameState.gameTimer - dt
    if gameState.gameTimer <= 0 then
        gameState.gameTimer = 0
        local counts = session.scoringSystem:countEntities(balls)
        gameState.timeOutWinner = session.scoringSystem:determineTimeOutWinner(counts)
    end

    for i = #slashes, 1, -1 do
        slashes[i]:update(dt)
        if slashes[i].life <= 0 then
            table.remove(slashes, i)
        end
    end

    session.navGrid:update(balls)

    if tileGrid then
        tileGrid:update(dt)
    end

    session.spatialGrid:clear()
    for i = 1, #balls do
        local b = balls[i]
        if session.currentMode.useFreezeRays and tileGrid and not b.dead and tileGrid:isChest(b.x, b.y) then
            tileGrid:removeChest(b.x, b.y)
            b.hasFreezeRay = true
            b.freezeRayCharges = b.freezeRayCharges + 3
            audio.playWorld("chest", b.x, b.y)
        end
        session.spatialGrid:insert(b)
    end

    for i = 1, #balls do
        balls[i]:update(dt, balls, session.navGrid, session.worldWidth, session.worldHeight, tileGrid, session.spatialGrid)
    end

    ball.updateDiscarded(dt)

    session.spatialGrid:clear()
    for i = 1, #balls do
        session.spatialGrid:insert(balls[i])
    end

    session.collisionSystem:resolveCollisions(balls, slashes, slash, tileGrid, session.worldWidth, session.worldHeight)

    for i = #balls, 1, -1 do
        if balls[i].dead then
            table.remove(balls, i)
        end
    end
end

function session.update(dt)
    local gameState = session.gameState
    if gameState.scene ~= "playing" then
        return
    end

    local sW, sH = love.graphics.getDimensions()
    if session.currentMode.useCamera then
        session.mainCamera:update(dt, sW, sH)
        session.mainCamera:clampToWorld(session.worldWidth, session.worldHeight, sW, sH)
    end

    if gameState:isGameOver() then
        session.interpAlpha = 1
        return
    end

    local scaledDt = dt * gameState.timeScale
    session.physicsAccumulator = session.physicsAccumulator + scaledDt

    local step = constants.physicsDt
    if session.physicsAccumulator > step * constants.physicsMaxSteps then
        session.physicsAccumulator = step * constants.physicsMaxSteps
    end

    while session.physicsAccumulator >= step do
        for _, b in ipairs(session.balls) do
            b:savePrevious()
        end
        for _, s in ipairs(session.slashes) do
            s:savePrevious()
        end
        session.physicsStep(step)
        session.physicsAccumulator = session.physicsAccumulator - step
    end

    session.interpAlpha = session.physicsAccumulator / step
end

function session.draw()
    local sW, sH = love.graphics.getDimensions()
    local counts = session.scoringSystem:countEntities(session.balls)
    local alpha = session.interpAlpha
    local currentMode = session.currentMode
    local mainCamera = session.mainCamera
    local frustumCuller = session.frustumCuller

    love.graphics.setLineWidth(1)

    if currentMode.useCamera then
        mainCamera:begin()
    end

    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("line", 0, 0, session.worldWidth, session.worldHeight)

    if session.tileGrid then
        session.tileGrid:draw(frustumCuller, mainCamera, sW, sH)
    end

    if settings.debug and (not currentMode.useCamera or mainCamera.scale >= 0.5) then
        debug.drawWorld(session.navGrid, currentMode, frustumCuller, mainCamera, session.worldWidth, session.worldHeight, sW, sH)
    end

    debug.drawGrid(currentMode, frustumCuller, mainCamera, session.worldWidth, session.worldHeight, sW, sH)

    love.graphics.setColor(1, 1, 1)
    ball.debugDetail = (not currentMode.useCamera) or (mainCamera.scale >= 0.5)
    ball.beginDraw()
    for i = 1, #session.balls do
        session.balls[i]:queueDraw(alpha, frustumCuller, mainCamera, sW, sH)
    end
    ball.flushDraw()
    for i = 1, #session.balls do
        session.balls[i]:drawFx()
    end
    ball.drawDiscarded(alpha, frustumCuller, mainCamera, sW, sH)

    for _, s in ipairs(session.slashes) do
        s:draw(alpha, frustumCuller, mainCamera, sW, sH)
    end

    if currentMode.useCamera then
        mainCamera:endDraw()
    end

    session.hudSystem:drawStats(session.gameState.gameTimer, counts, session.gameState.timeScale, settings)

    if not session.gameState.winner then
        session.gameState.winner = session.scoringSystem:checkExtinctionWinner(counts)
    end

    local finalWinner = session.gameState:getFinalWinner()
    if finalWinner then
        session.hudSystem:drawWinnerScreen(finalWinner, session.gameState.winner ~= nil)
    end

    if settings.showHints then
        if currentMode.useCamera then
            love.graphics.setColor(1, 1, 1, 0.7)
            love.graphics.print("WASD/Arrows: Pan | Mouse Wheel: Zoom | Esc: Menu", sW - 360, sH - 20)
        else
            love.graphics.setColor(1, 1, 1, 0.7)
            love.graphics.print("Esc: Menu | R: Restart | F: Fast Forward", sW - 280, sH - 20)
        end
    end
end

function session.keypressed(key, menuSystem)
    local action = session.inputHandler:handleKeyPress(key)
    if action == "menu" then
        session.returnToMenu(menuSystem)
    elseif action == "restart" then
        session.startGame(session.gameState.mode)
    end
end

function session.wheelmoved(y)
    if not session.currentMode or not session.currentMode.useCamera then
        return
    end
    local mx, my = love.mouse.getPosition()
    session.mainCamera:zoom(y, mx, my)
end

return session
