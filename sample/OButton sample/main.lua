application:setKeepAwake(true)

local screenManager = ScreenManager.new()
local a = MainScreen.new()
screenManager:addScreen(a)
stage:addChild(screenManager)