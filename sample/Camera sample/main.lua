application:setKeepAwake(true)

local screenManager = ScreenManager.new()
local a = MainGameScreen.new()
screenManager:addScreen(a)
stage:addChild(screenManager)