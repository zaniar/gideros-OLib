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

GameScreen = Core.class(Sprite)

--[[
/// A screen is a single layer that has update and draw logic, and which
/// can be combined with other layers to build up a complex menu system.
/// For instance the main menu, the options menu, the "are you sure you
/// want to quit" message box, and the main game itself are all implemented
/// as screens.
--]]
ScreenState = {}
ScreenState.TRANSITION_ON = 1
ScreenState.ACTIVE = 2
ScreenState.TRANSITION_OFF = 3
ScreenState.HIDDEN = 4

function GameScreen:init()
	self._isPopup = false
	self._transitionOnTime = 0
	self._transitionOffTime = 0
	self._transitionPosition = 0
	self._screenState = ScreenState.TRANSITION_ON
	self._isExiting = false
	self._otherScreenHasFocus = false
	self._screenManager = nil

	self.removedHandler = EventHandler.new(self) -- will be raised if this screen is removed from the screen manager
	self.addedHandler = EventHandler.new(self) -- will be raised if this screen is added to the screen manager
end

function GameScreen:getScreenState()
	return self._screenState
end

function GameScreen:setScreenState(value)
	self._screenState = value
end	

function GameScreen:isExiting()
	return self._isExiting
end

function GameScreen:setIsExiting(val)
	self._isExiting = val
end

function GameScreen:isActive()
	return not self._otherScreenHasFocus and (self._screenState == ScreenState.TRANSITION_ON or self._screenState == ScreenState.ACTIVE)
end

function GameScreen:getScreenManager()
	return self._screenManager
end

function GameScreen:setScreenManager(value)
	self._screenManager = value
end

function GameScreen:update(elapsedTime, otherScreenHasFocus, coveredByOtherScreen)	
	
	self._otherScreenHasFocus = otherScreenHasFocus
	
	if(self._isExiting) then
		--If the screen is going away to die, it should transition off.
		self._screenState = ScreenState.TransitionOff;

		if (not self:_updateTransition(elapsedTime, self._transitionOffTime, 1)) then		
			--When the transition finishes, remove the screen.
			self:getScreenManager():removeScreen(self)
		end
	elseif(coveredByOtherScreen) then
		--If the screen is covered by another, it should transition off.
		if (self:_updateTransition(elapsedTime, self._transitionOffTime, 1)) then		
			--Still busy transitioning.
			self._screenState = ScreenState.TransitionOff;		
		else		
			--Transition finished!
			self._screenState = ScreenState.Hidden;
		end
	else
		--Otherwise the screen should transition on and become active.
		if (self:_updateTransition(elapsedTime, self._transitionOnTime, -1)) then		
			--Still busy transitioning.
			self._screenState = ScreenState.TransitionOn;
		else		
			--Transition finished!
			self._screenState = ScreenState.Active;
		end
	end
	
end

--[[
	Helper for updating the screen transition position.
--]]
function GameScreen:_updateTransition(gameTime, time, direction)
	--How much should we move by?
	local transitionDelta

	if (time == 0) then
		transitionDelta = 1
	else
		transitionDelta = gameTime / time
	end

	--Update the transition position.
	self._transitionPosition = self._transitionOffTime + (transitionDelta * direction)

	--Did we reach the end of the transition?
	if (((direction < 0) and (self._transitionPosition <= 0)) or
		((direction > 0) and (self._transitionPosition >= 1)))
	then
		self._transitionPosition = self:_clamp(self._transitionPosition, 0, 1)
		return false
	end

	--Otherwise we are still busy transitioning.
	return true
end

--[[
/// Allows the screen to handle user input. Unlike Update, this method
/// is only called when the screen is active, and not when some other
/// screen has taken the focus.
--]]
--abstract
function GameScreen:handleInput(input)
end

--virtual
--otomatis dipanggil oleh screen manager ketika screen ini ditambahkan ke screen manager
function GameScreen:onAddScreen()
end

--[[
/// Tells the screen to go away. Unlike ScreenManager.RemoveScreen, which
/// instantly kills the screen, this method respects the transition timings
/// and will give the screen a chance to gradually transition off.
--]]
function GameScreen:exitScreen()
	if(self._transitionOffTime == 0) then		
		self.removedHandler:raiseEvent(nil)
		self:getScreenManager():removeScreen(self)
	else
		self._isExiting = true
	end
end

function GameScreen:_clamp(val, min, max)
	if(val < min) then
		val = min
	elseif(val > max) then
		val = max
	end
	return val
end

function GameScreen.convertSpriteLocalPos(sourceSprite, localX, localY, destSprite)
	local x, y = localX, localY
	x, y = sourceSprite:localToGlobal(x, y)
	x, y = destSprite:globalToLocal(x, y)
	return x, y	
end