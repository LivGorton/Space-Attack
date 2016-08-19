-----------------------------------------------------------------------------------------
--
-- game.lua
--
-----------------------------------------------------------------------------------------

-- hide status bar
display.setStatusBar(display.HiddenStatusBar)

-- some introductory declarations
local composer = require( "composer" )
local scene = composer.newScene()
local score = 0
local player
local enemy
local lives = 3
local random = math.random
local ceil = math.ceil
local atan2 = math.atan2
local pi = math.pi


-- the required physics declarations
local physics = require "physics"
physics.start()
physics.setGravity(0,0)


--------------------------------------------

-- forward declarations and other locals
local screenW, screenH, halfW = display.actualContentWidth, display.actualContentHeight, display.contentCenterX

function scene:create( event )

	local sceneGroup = self.view

	-- play background music
	local backgroundMusic = audio.loadStream( "Audio/music_background.wav" )
	local playMusic = audio.play(backgroundMusic, {loops = -1})

	-- display the background image
	local background = display.newImageRect( "Images/background.jpg", display.actualContentWidth, display.actualContentHeight )
	background.anchorX = 0
	background.anchorY = 0
	background.x = 0 + display.screenOriginX 
	background.y = 0 + display.screenOriginY

	-- display score count
	local displayScore = display.newText(score, display.contentCenterX, display.contentWidth / 4, "Fonts/Arial Narrow.ttf", 35)
	displayScore.x = 20
	displayScore.y = 15

	-- display the player
	-- to do, have it centered rather than manual coords
	player = display.newImage("Images/player.png")
	player.x = 161
	player.y = 480

end

-- function to rotate the player
-- credit to the demo for the idea of how to do this
local function rotateShip(x, y)

	local angle = ceil(atan2( (y - player.y), (x - player.x)) * 180 / pi) + 90
	player.rotation = angle

end



-- function for the player shooting
local function shoot( event )

	local x, y = event.x, event.y
	rotateShip(x, y)

	local laser = display.newImage("Images/laser.png")
	laser.x = player.x
	laser.y = player.y
	transition.to(laser, {time=300, x=x, y=y, onComplete=shotDone})
	
	local function shotDone(obj)
		transition.to ( blast, { time=200, xScale=2, yScale=2, alpha=0, onComplete=killObj } )
		killObj(obj)
	end

end

local function highscore(score)

	local highscoreFile = io.open("highscore.txt", "r")
	
end

function scene:hide( event )
	local sceneGroup = self.view
	
	local phase = event.phase
	
	if event.phase == "will" then
		-- Called when the scene is on screen and is about to move off screen
		--
		-- INSERT code here to pause the scene
		-- e.g. stop timers, stop animation, unload sounds, etc.)
		physics.stop()
	elseif phase == "did" then
		-- Called when the scene is now off screen
	end	

	sceneGroup:insert(background)
	sceneGroup:insert(displayScore)
	sceneGroup:insert(backgroundMusic)
end

function scene:destroy( event )

	-- Called prior to the removal of scene's "view" (sceneGroup)
	-- 
	-- INSERT code here to cleanup the scene
	-- e.g. remove display objects, remove touch listeners, save state, etc.
	local sceneGroup = self.view
	
	package.loaded[physics] = nil
	physics = nil
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)
Runtime:addEventListener("tap", shoot)

-----------------------------------------------------------------------------------------

return scene