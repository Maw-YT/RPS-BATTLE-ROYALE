local gamestate = require "src.core.gamestate"
local menu = require "src.ui.menu"
local settings = require "src.core.settings"
local audio = require "src.audio"
local session = require "src.sim.session"

local menuSystem
local gameState
local defaultFont

local function handleMenuAction(action)
    if not action then
        return
    end
    if action == "play" then
        gameState.scene = "gamemode_menu"
        menuSystem.selected = 1
        menuSystem.hover = nil
    elseif action == "settings" then
        gameState.scene = "settings_menu"
        menuSystem.selected = 1
        menuSystem.hover = nil
        menuSystem.settingsPanel:reset()
    elseif action == "settings_changed" then
        -- already applied
    elseif action == "quit" then
        love.event.quit()
    elseif action == "back" then
        settings.save()
        gameState.scene = "main_menu"
        menuSystem.selected = 1
        menuSystem.hover = nil
    elseif action == "fortnite" or action == "simple" then
        session.startGame(action)
    end
end

function love.load()
    math.randomseed(os.time())
    gameState = gamestate.new()
    menuSystem = menu.new()
    session.bind(gameState)
    defaultFont = love.graphics.newFont(12)
    love.graphics.setFont(defaultFont)
    settings.load()
    audio.load()
    settings.apply()
    audio.playMusic("menu")
end

function love.update(dt)
    if gameState.scene == "settings_menu" and menuSystem.settingsPanel.drag then
        if love.mouse.isDown(1) then
            local mx, my = love.mouse.getPosition()
            menuSystem:mousemoved(mx, my, gameState.scene)
        else
            handleMenuAction(menuSystem:mousereleased(gameState.scene))
        end
    end
    session.update(dt)
end

function love.draw()
    if gameState.scene == "main_menu" then
        menuSystem:drawMainMenu()
        return
    elseif gameState.scene == "gamemode_menu" then
        menuSystem:drawGamemodeMenu()
        return
    elseif gameState.scene == "settings_menu" then
        menuSystem:drawSettingsMenu()
        return
    end

    love.graphics.setFont(defaultFont)
    session.draw()
end

function love.keypressed(key)
    if gameState.scene == "main_menu" or gameState.scene == "gamemode_menu" or gameState.scene == "settings_menu" then
        handleMenuAction(menuSystem:keypressed(key, gameState.scene))
        return
    end
    session.keypressed(key, menuSystem)
end

function love.mousepressed(x, y, button)
    if button ~= 1 then
        return
    end
    if gameState.scene == "main_menu" or gameState.scene == "gamemode_menu" or gameState.scene == "settings_menu" then
        handleMenuAction(menuSystem:mousepressed(x, y, gameState.scene))
    end
end

function love.mousemoved(x, y)
    if gameState.scene == "settings_menu" then
        menuSystem:mousemoved(x, y, gameState.scene)
    end
end

function love.mousereleased(x, y, button)
    if button ~= 1 then
        return
    end
    if gameState.scene == "settings_menu" then
        handleMenuAction(menuSystem:mousereleased(gameState.scene))
    end
end

function love.quit()
    settings.save()
end

function love.wheelmoved(x, y)
    if gameState.scene == "settings_menu" then
        menuSystem:wheelmoved(y, gameState.scene)
        return
    end
    if gameState.scene == "playing" then
        session.wheelmoved(y)
    end
end
