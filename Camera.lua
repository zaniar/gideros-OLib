--[[
https://github.com/bysreg/gideros-OLib

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

Camera = Core.class(Sprite)

function Camera:init(worldWidth, worldHeight) 	
	self.worldWidth = worldWidth
	self.worldHeight = worldHeight
	self.velocity = {x = 0, y = 0}			
	self.minZoom = 0.8
	self.maxZoom = 1
	
	self.minPosition = {x = application:getContentWidth() / 2, y = application:getContentHeight() / 2}
	self.maxPosition = {x = self.worldWidth - application:getContentWidth() / 2 , y = self.worldHeight - application:getContentHeight() / 2}	
		
	self._currentPosition = {x = application:getContentWidth() / 2, y = application:getContentHeight() / 2}
	self._targetZoom = 1
	self._currentZoom = 1
	self._lengthTransX = 0
	self._lengthTransY = 0
	
	--for translate tween
	self._elapsedTimeTranslation = 0
	self._timeTranslation = 0
	self._isActiveTranslation = false
	self._firstPos = {x = 0, y = 0}	

	local minZoomedHeight = application:getContentHeight() / worldHeight
	local minZoomedWidth = application:getContentWidth() / worldWidth
	if minZoomedHeight < minZoomedWidth then
		self.minZoom = minZoomedWidth
	else
		self.minZoom = minZoomedHeight
	end
end

function Camera:setMaxZoom(value) 
	self.maxZoom = value
end

function Camera:cameraPosToSpritePos(camX, camY)
	local spriteX = (application:getContentWidth() / 2) - (camX * self:getScale())
	local spriteY = (application:getContentHeight() / 2) - (camY * self:getScale())
	
	return spriteX, spriteY
end

function Camera:spritePosToCameraPos(spriteX, spriteY)
	local camX = (-spriteX / self:getScale()) + ((application:getContentWidth() / 2) / self:getScale())	
	local camY = (-spriteY / self:getScale()) + ((application:getContentHeight() / 2) / self:getScale())	
	
	return camX, camY
end

function Camera:isActiveTranslation()
	return self._isActiveTranslation
end

function Camera:getCameraX()
	return (-self:getX() / self:getScale()) + ((application:getContentWidth() / 2) / self:getScale())	
end

function Camera:getCameraY()
	return (-self:getY() / self:getScale()) + ((application:getContentHeight() / 2) / self:getScale())	
end

function Camera:getCameraPosition()
	return self:getCameraX(), self:getCameraY() 		
end

function Camera:setCameraPosition(camX, camY)
	self._currentPosition.x, self._currentPosition.y = self:_adjustPosition(camX, camY, self:getScale())	
	local spriteX, spriteY = self:cameraPosToSpritePos(self._currentPosition.x, self._currentPosition.y)	
	self:setPosition(spriteX, spriteY)			
end

function Camera:getZoom()
	return self._currentZoom
end

function Camera:zoom(newScale)	
	if(newScale > self.maxZoom) then
		newScale = self.maxZoom
	elseif(newScale < self.minZoom) then
		newScale = self.minZoom
	end
		
	self:setScale(newScale)	

	self._currentZoom = self:getScale()
	self._targetZoom = self._currentZoom
	
	self.minPosition.x = application:getContentWidth() / 2 / newScale
	self.minPosition.y = application:getContentHeight() / 2 / newScale
	self.maxPosition.x = self.worldWidth - (application:getContentWidth() / 2 / newScale)
	self.maxPosition.y = self.worldHeight - (application:getContentHeight() / 2 / newScale)	
	
	if(self.maxPosition.y < self.minPosition.y) then
		self.minPosition.y = self.worldHeight / 2
		self.maxPosition.y = self.worldHeight / 2
	end
	
	if(self.maxPosition.x < self.minPosition.x) then
		self.minPosition.x = self.worldWidth / 2
		self.maxPosition.x = self.worldWidth / 2
	end
	
	self._currentPosition.x, self._currentPosition.y = self:_adjustPosition(self._currentPosition.x, self._currentPosition.y)
	
	self:setPosition(self:cameraPosToSpritePos(self._currentPosition.x, self._currentPosition.y))			
	
	--print("zoom", self._currentZoom)
	
	--print("test", offsetX, offsetY, oldCenterX*(k-1), oldCenterY*(k-1))	
	--print("pos", self:getX(), self:getY(), self.minPosition.x, self.minPosition.y, self.maxPosition.x, self.maxPosition.y)
	--print("center", self:getCameraX(), self:getCameraY(), newScale, self.minPosition.y, self.maxPosition.y)	
end

function Camera:moveCamera(deltaX, deltaY)	
	local newPosX = self._currentPosition.x + deltaX
	local newPosY = self._currentPosition.y + deltaY		
	self._currentPosition.x, self._currentPosition.y = self:_adjustPosition(newPosX, newPosY, self:getScale())
		
	self:setPosition(self:cameraPosToSpritePos(self._currentPosition.x, self._currentPosition.y))		
	--print("move ", self:getPosition())
	--print("center ", self:getCameraPosition())
end

function Camera:cancelTween()
	self._isActiveTranslation = false	
end

function Camera:tweenCameraTo(newX, newY, newScale, duration, tweenCompleteFunc)
	if(newScale == nil) then
		newScale = self:getScale()
	end
	
	if(newScale > self.maxZoom) then
		newScale = self.maxZoom
	elseif(newScale < self.minZoom) then
		newScale = self.minZoom
	end
	self._targetZoom = newScale	
		
	local minPosition = {}
	local maxPosition = {}
	minPosition.x = application:getContentWidth() / 2 / self._targetZoom
	minPosition.y = application:getContentHeight() / 2 / self._targetZoom
	maxPosition.x = self.worldWidth - (application:getContentWidth() / 2 / self._targetZoom)
	maxPosition.y = self.worldHeight - (application:getContentHeight() / 2 / self._targetZoom)
	if(newX > maxPosition.x) then
		newX = maxPosition.x
	end
	if(newY > maxPosition.y) then
		newY = maxPosition.y
	end	
	if(newX < minPosition.x) then
		newX = minPosition.x
	end
	if(newY < minPosition.y) then
		newY = minPosition.y
	end			
	
	self._firstPos.x, self._firstPos.y = self._currentPosition.x, self._currentPosition.y
	self._lengthTransX = newX - self._currentPosition.x
	self._lengthTransY = newY - self._currentPosition.y
	self._elapsedTimeTranslation = 0
	self._timeTranslation = duration
	self._isActiveTranslation = true
end

function Camera:setVelocity(velocityX, velocityY)	
	self.velocity.x, self.velocity.y = velocityX, velocityY
end

function Camera:convertScreenToWorld(x, y)
	return self:globalToLocal(x, y)
end

function Camera:update(deltaTime)	
	--update zooming
	local deltaZoom = self._targetZoom - self._currentZoom
	local zoomDistance = math.abs(deltaZoom)
	local zoomInertia
	if(zoomDistance < 0.01) then
		zoomInertia = math.pow(zoomDistance / 5, 2)
	else
		zoomInertia = 0.4
	end
	
	self._currentZoom = self._currentZoom + (10 * deltaZoom * zoomInertia * deltaTime)
	
	if(math.abs(self._targetZoom - self._currentZoom) > 0.07) then		
		self.minPosition.x = application:getContentWidth() / 2 / self._currentZoom
		self.minPosition.y = application:getContentHeight() / 2 / self._currentZoom
		self.maxPosition.x = self.worldWidth - (application:getContentWidth() / 2 / self._currentZoom)
		self.maxPosition.y = self.worldHeight - (application:getContentHeight() / 2 / self._currentZoom)
		
		self._currentPosition.x, self._currentPosition.y = self:_adjustPosition(self._currentPosition.x, self._currentPosition.y)
	end
	
	--update position
	if(self._isActiveTranslation) then		
		self:_tweenTranslate(deltaTime)
	end
	
	--update speed
	if(self.velocity.x ~= 0 or self.velocity.y ~= 0) then
		--[[
		self._currentPosition.x = self._currentPosition.x + self.velocity.x * deltaTime * 16
		self._currentPosition.y = self._currentPosition.y + self.velocity.y * deltaTime * 16
		print("speed 1", self._currentPosition.x, self._currentPosition.y, self.velocity.x, self.velocity.y)
		self._currentPosition.x, self._currentPosition.y = self:_adjustPosition(self._currentPosition.x, self._currentPosition.y)		
		print("speed 2", self._currentPosition.x, self._currentPosition.y, self.velocity.x, self.velocity.y)
		--]]
		
		self:moveCamera(self.velocity.x * deltaTime * 16, self.velocity.y * deltaTime * 16)
		
		self.velocity.x = self.velocity.x * 0.97
		self.velocity.y = self.velocity.y * 0.97
		
		if(math.abs(self.velocity.x) < 1) then
			self.velocity.x = 0
		end
		
		if(math.abs(self.velocity.y) < 1) then
			self.velocity.y = 0
		end
	end
	
	--print("last", self._currentZoom)
	
	self:setScale(self._currentZoom)
	self:setPosition(self:cameraPosToSpritePos(self._currentPosition.x, self._currentPosition.y))	
end

function Camera:_tweenTranslate(deltaTime)
	if(self._elapsedTimeTranslation + deltaTime > self._timeTranslation) then
		self._isActiveTranslation = false
		self._currentPosition.x, self._currentPosition.y = self._firstPos.x + self._lengthTransX, self._firstPos.y + self._lengthTransY
	else
		self._elapsedTimeTranslation = self._elapsedTimeTranslation + deltaTime
		self._currentPosition.x = self:_easingFunc(self._elapsedTimeTranslation, self._firstPos.x, self._lengthTransX, self._timeTranslation)
		self._currentPosition.y = self:_easingFunc(self._elapsedTimeTranslation, self._firstPos.y, self._lengthTransY, self._timeTranslation)
	end
	
	--print("test", self._currentPosition.x, self._currentPosition.y)
end

function Camera:_easingFunc(elapsedTime, start, change, duration)
	elapsedTime = elapsedTime / duration;
    return -change * elapsedTime * (elapsedTime - 2) + start;
end

function Camera:_adjustPosition(x, y, scale)	
	if(x > self.maxPosition.x) then
		x = self.maxPosition.x
	end
	if(y > self.maxPosition.y) then
		y = self.maxPosition.y
	end	
	if(x < self.minPosition.x) then
		x = self.minPosition.x
	end
	if(y < self.minPosition.y) then
		y = self.minPosition.y
	end		
	return x, y
end