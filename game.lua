-----------------------------------------------------------------------------------------
--
-- game.lua
--
-- This is not completely done. What I would do if I had more time is
-- figure out the bug where the menu scene doesn't load 
-- add a highscore feature that would be displayed on the menu screen (a semi finished function for this is commented out starting at line 91)
-----------------------------------------------------------------------------------------

-- hide status bar
display.setStatusBar(display.HiddenStatusBar)

-- some introductory declarations
local composer = require( "composer" )
local scene = composer.newScene()

-- forward declarations and other locals
local screenW, screenH, halfW = display.actualContentWidth, display.actualContentHeight, display.contentCenterX
local random = math.random
local ceil = math.ceil
local atan2 = math.atan2
local pi = math.pi

-- the required physics declarations
local physics = require "physics"

local playMusic

local score = 0
local lives = 3
local player

local collisionEvent

local background
local displayScore
local lifeCount

function scene:create( event )
    local sceneGroup = self.view
    
    -- display the background image
    background = display.newImageRect( "Images/background.jpg", display.actualContentWidth, display.actualContentHeight )
    background.anchorX = 0
    background.anchorY = 0
    background.x = 0 + display.screenOriginX 
    background.y = 0 + display.screenOriginY
    
    -- display score count
    displayScore = display.newText(score, display.contentCenterX, display.contentWidth / 4, "Fonts/Arial Narrow.ttf", 35)
    displayScore.x = 20
    displayScore.y = 15
    
    -- display the player
    player = display.newImageRect("Images/player.png", 90, 90)
    player.x = display.contentCenterX
    player.y = 480
    player.name = "player"
    
    -- display lives
    local lifeImage = display.newImage("Images/life.png")
    lifeImage.x = 290
    lifeImage.y = 15
    
    lifeCount = display.newText(lives, display.contentCenterX, display.contentHeight, "Fonts/Arial Narrow.ttf", 35)
    lifeCount.x = 250
    lifeCount.y = 15
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Local Functions
-------------------------------------------------------------------------------
-------------------------------------------------
-------------------------------------------------

local function killObj(obj)

      obj:removeSelf()
      obj.isLive = false
end


-------------------------------------------------
-------------------------------------------------
-------------------------------------------------
-- highscore function. Called once game is over
-- to check if the player receieved a high score
-------------------------------------------------
--local function highscore(score)
--    local path = system.pathForFile("highscore.txt", system.ResourceDirectory)
--    local highscoreFile = io.open(path, "r")
--    
--    -- if the file is nil then print an error to the console
--    if not highscoreFile then
--        print("ERROR: " .. "Highscore file is nil or not opening properly!" )
--    else
--        -- get the content of highscoreFile
--        for line in highscoreFile:lines() do
--            highscoreContent = line
--        end
--        
--	io.close(highscoreFile)
--    end
--    -- remove file contents from the variable
--    highscoreFile = nil
--end

-------------------------------------------------
-------------------------------------------------
-------------------------------------------------
-- function to rotate the player
-- credit to general game dev for this code. It's
-- known for getting an angle. It was used in the
-- demo as well.
-------------------------------------------------
local function rotateShip(x, y)
    local angle = ceil(atan2( (y - player.y), (x - player.x)) * 180 / pi) + 90
    player.rotation = angle
end

-------------------------------------------------
-------------------------------------------------
-------------------------------------------------
-- update score value and display
-------------------------------------------------
local function addToScore(n)
    score = score + n
    displayScore.text = score
end
--
local function enemyKilled()
    addToScore(1)
end

-------------------------------------------------
-------------------------------------------------
-------------------------------------------------
-- update score value and display
-------------------------------------------------
local function generateEnemy()
    local enemy = display.newImageRect("Images/asteroid.png", 60, 60)
    physics.addBody(enemy, "dynamic", {radius=30, isSensor=true})
    enemy.x = math.random(0, display.viewableContentWidth)
    enemy.y = -enemy.contentHeight
    if score > 40 then
    	transition.to(enemy, {time=600, x=player.x, y=player.y})

    elseif score > 30 then
    	transition.to(enemy, {time=1000, x=player.x, y=player.y})
    elseif score > 20 then
    	transition.to(enemy, {time=1250, x=player.x, y=player.y})
    elseif score > 10 then
    	transition.to(enemy, {time=1500, x=player.x, y=player.y})
	else
    	transition.to(enemy, {time=2500, x=player.x, y=player.y})
    end

    enemy.name = "enemy"
    enemy.isLive = false

end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Event Function
-------------------------------------------------------------------------------
function collisionEvent(event)
    -- Strike began...
    if event.phase == "began" then
        
        local obj1 = event.target
        local obj2 = event.other
        
        -- laser strike on enemy
        if (obj1.name == "laser" and obj2.name == "enemy") or
           (obj2.name == "laser" and obj1.name == "enemy") then
            
            -- !!!! the laser and enemy are killed here !!!!!
            killObj(obj1)
            killObj(obj2)
            addToScore(1)
            
            timer.performWithDelay(250, function() generateEnemy() end)
           
        -- laser strike on player
        elseif (obj1.name == "enemy" and obj2.name == "player") or
               (obj2.name == "enemy" and obj1.name == "player") then
            
            if obj1.name == "enemy" then
                killObj(obj1)
            end
            if obj2.name == "enemy" then
                killObj(obj2)
            end
            
            if lives == 0 then
                composer.gotoScene("menu", "fade", 500)
            else
                lives = lives - 1
                lifeCount.text = lives
                
                -- cannot generate physics object within collision event function
                -- so.. give some delay out of the current trunk
                timer.performWithDelay(250, function() generateEnemy() end)
            end
        end
    
    -- Strike end...    
    elseif event.phase == "ended" then
        --print("collision ended")
    end
end


-------------------------------------------------
-------------------------------------------------
-------------------------------------------------
-- tap event function
-------------------------------------------------
-- function for the player shooting
-- credit to a user on stackoverflow for helping me figure this out (with the bullets continuing on past the mouse click)
local function shoot( event )
    -- get width and height of phone
    -- unsure of how to do this automatically, so I manually did it for iphone 5
    local width, height = 640, 1136
    local ex, ey = event.x, event.y -- Where player have clicked/tapped/etc
    local px, py = player.x, player.y -- Current position of player
    local speed = 1.5
    
    -- rotate player
    rotateShip(ex, ey)
    
    -- play sound for shooting
    audio.play(global_shootSound)
    
    local laser = display.newImage("Images/laser.png")
    laser.x, laser.y = player.x, player.y
    physics.addBody(laser, "dynamic", {isSensor=true})
    laser.isBullet = true
    laser.setGravityScale = 0
    
    -- better turn to match the player rotation
    laser.rotation = player.rotation
    
    -- Borders: bx, by
    local bx, by = width, height
    if ex < px then
        bx = 0
    end
    if ey < py then
        by = 0
    end
    
    -- px = ex will generate a divide-by-zero error at the following statements
    if px == ex then ex = px + 1 end
    
    -- Let's get our target coordinates
    local tx, ty = bx
    ty = ((py-ey)/(px-ex))*bx+py-((py-ey)/(px-ex))*px
    if ty > height or ty < 0 then
        ty = by
        tx = (by-py+((py-ey)/(px-ex))*px)/((py-ey)/(px-ex))
    end
    
    -- Let's get animation time now!
    local distance = math.sqrt((tx-px)*(tx-px)+(ty-py)*(ty-py))
    local time = distance/speed
    
    -- Now, just shoot
    -- there's a better way to do this but I am not familiar enough with the syntax to figure out to velocity*dt thing
    local function shotDone()
        if laser and laser.isLive then -- check if laser alive
            laser.isLive = false
            laser:removeEventListener("collision", collisionEvent)
            killObj(laser)
            laser = nil
        end
    end
    transition.to(laser, {time=time, x=tx, y=ty, onComplete=shotDone})
    laser.name = "laser"
    laser.isLive = true
    laser:addEventListener("collision", collisionEvent)
end

-------------------------------------------------
-------------------------------------------------
-------------------------------------------------
-- touch Event Function
-------------------------------------------------
local function touchFunc(event)
    local obj = event.target
    
    -- Key pressed --
    if(event.phase == "began") then
        display.getCurrentStage():setFocus(obj)
        shoot(event)
    
    -- Key released --
    elseif(event.phase == "ended" or event.phase == "cancelled") then
        display.getCurrentStage():setFocus(nil)
    end -- touch began, moved, ended, cancelled
    
    return true    
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Scene Function
-------------------------------------------------------------------------------
function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase
    
    if phase == "will" then
        -- Called when the scene is still off screen and is about to move on screen
        -- enable physics
        physics.start()
        physics.setGravity(0,0)
        
    elseif phase == "did" then
        -- Called when the scene is now on screen
        -- 
        -- INSERT code here to make the scene come alive
        -- e.g. start timers, begin animation, play audio, etc.
        
        -- play background music
        playMusic = audio.play(global_backgroundMusic, {loops = -1})
        
        -- enable tap
        background:addEventListener("touch", touchFunc)
        
        physics.addBody(player, "dynamic", {radius = 20, isSensor=true})
        player:addEventListener("collision", collisionEvent)
        
        -- state generation of enemies
        generateEnemy()
    end	
end

function scene:hide( event )
    local sceneGroup = self.view
    
    local phase = event.phase
    
    if event.phase == "will" then
        -- Called when the scene is on screen and is about to move off screen
        --
        -- INSERT code here to pause the scene
        -- e.g. stop timers, stop animation, unload sounds, etc.)
        
        -- stop background music
        audio.stop(playMusic)
        
        -- disable tap
        --Runtime:remvoeEventListener("tap", shoot)
        background:removeEventListener("touch", touchFunc)
        
        -- disable physics
        player:removeEventListener("collision", collisionEvent)
        physics.stop()
        
    elseif phase == "did" then
        -- Called when the scene is now off screen
    end	
    
end

function scene:destroy( event )
    -- Called prior to the removal of scene's "view" (sceneGroup)
    -- 
    -- INSERT code here to cleanup the scene
    -- e.g. remove display objects, remove touch listeners, save state, etc.
    local sceneGroup = self.view
    
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

-----------------------------------------------------------------------------------------

return scene
