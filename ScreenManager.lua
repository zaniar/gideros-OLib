--[[
https://github.com/bysreg/gideros-OLib

translated from XNA screen manager by bysreg

Copyright (C) 2013 Hilman Beyri(hilmanbeyri@gmail.com)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction, 
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do 
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--]]


ScreenManager = Core.class(Sprite)

function ScreenManager:init()		
	self._screens = {}
	self._screensToUpdate = {}	
	self._touchHandler = TouchHandler.new(self)
	self._isTopOtherScreen = true	
	
	self:addEventListener(Event.ENTER_FRAME, self._onEnterFrame, self)
end

function ScreenManager._onEnterFrame(self, event)	
	local gameTime = event.deltaTime
	
	--update touch
	self._touchHandler:update(event)
	
	--Make a copy of the master screen list, to avoid confusion if
    --the process of updating one screen adds or removes others.
	for k in pairs(self._screensToUpdate) do
		self._screensToUpdate[k] = nil
	end
	
	for i=1, #self._screens do
		self._screensToUpdate[i] = self._screens[i]
	end
	
	local otherScreenHasFocus = false
	local coveredByOtherScreen = false	

	--Loop as long as there are screens waiting to be updated.
	while(#self._screensToUpdate > 0) do
		--Pop the topmost screen off the waiting list.
		local screen = table.remove(self._screensToUpdate)
		
		--Update the screen
		screen:update(gameTime, otherScreenHasFocus, coveredByOtherScreen)
		
		if(screen.ScreenState == ScreenState.TransitionOn or screen.ScreenState == ScreenState.Active) then
			--If this is the first active screen we came across,
			--give it a chance to handle input, if there is any.
			if (not otherScreenHasFocus) then
				if(self._touchHandler:getTouchStates().size ~= 0 or self._touchHandler:getQueue().size ~= 0) then
					screen:handleInput(self._touchHandler)			
				end
				otherScreenHasFocus = true
			end

			--If this is an active non-popup, inform any subsequent
			--screens that they are covered by it.
			if (not screen.IsPopup) then
				coveredByOtherScreen = true
			end
		end
	end	
end

function ScreenManager:addScreen(screen)	
	screen:setScreenManager(self) 	
	screen:setIsExiting(false)	
	
	self._screens[#self._screens+1] = screen
	self:addChild(screen)	
	screen.addedHandler:raiseEvent(nil)
	screen:onAddScreen()
end

--[[
	Removes a screen from the screen manager. You should normally
	use GameScreen.ExitScreen instead of calling this directly, so
	the screen can gradually transition off rather than just being
	instantly removed.
--]]
function ScreenManager:removeScreen(screen)	
	for i=1, #self._screens do
		if(self._screens[i] == screen) then
			table.remove(self._screens, i)			
			break			
		end
	end	
	
	for i=1, #self._screensToUpdate do
		if(self._screensToUpdate[i] == screen) then
			table.remove(self._screensToUpdate, i)			
			break
		end
	end
	if(screen:getParent() == self) then
		self:removeChild(screen)		
		screen:removeFromParent()								
		Timer.delayedCall(100,
			function()
				collectgarbage()
			end		
		)		
	end
end

--[[
	check if there's screen object in the Screen Stack
--]]
function ScreenManager:isScreenInStack(screen)
	for i=1, #self._screens do
		if(self._screens[i] == screen) then
			return true
		end
	end
	return false
end

--[[
	close every screen above a particular screen using their own exitScreen
--]]
function ScreenManager:closeEverythingAbove(screen)
	local found_index = #self._screens
	for i=1, #self._screens do
		if(self._screens[i] == screen) then
			found_index = i
			break
		end
	end	

	for i=#self._screens, found_index + 1, -1 do
		self._screens[i]:exitScreen()
	end 
end

--return screens count in the stack
function ScreenManager:getScreenCount()
	return #self._screens
end