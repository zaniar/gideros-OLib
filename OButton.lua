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

OButton = Core.class(Bitmap)

--disable button tidak terpengaruh dengan visible button. 

function OButton:init(texture, x, y)
	self.FEEDBACK_ZOOM = nil
	self.FEEDBACK_ALPHA = nil
	self._normalfzoom = 1 -- zoom when user release the button, only used when self._isFeedBackZoom = true	
	self._normalfalpha = 1
	
	--properties
	self.clickedHandler = EventHandler.new(self)
	self.touchDownHandler = EventHandler.new(self)
	self.touchUpHandler = EventHandler.new(self)
	
	self._isOnHold = false
	self._isDisable = false
	self._isFeedBackZoom = false
	self._isFeedBackAlpha = false
	self._aabb = nil	
end

--relative to the local coordinate of the button(local coordinate could change because of setAnchorPoint function)
function OButton:setHitArea(xl, yl, xu, yu)
	self._aabb = AABB.new(xl, yl, xu, yu)
end

function OButton:setFeedBackZoom(endZoom, normalZoom)
	if endZoom ~= nil then self.FEEDBACK_ZOOM = endZoom
	else self.FEEDBACK_ZOOM = 1.1 end
	
	if(normalZoom ~= nil) then
		self._normalfzoom = normalZoom
		self:setScale(normalZoom)
	end
	
	self._isFeedBackZoom = true	
end

function OButton:setFeedBackAlpha(endAlpha, normalAlpha)
	if endAlpha ~= nil then self.FEEDBACK_ALPHA = endAlpha
	else self.FEEDBACK_ALPHA = 0.7 end
	
	if(normalAlpha ~= nil) then
		self._normalfalpha = normalAlpha
	end
	
	self._isFeedBackAlpha = true
end

function OButton:setDisable(val)
	self._isDisable = val	
end

function OButton:getDisable()
	return self._isDisable
end

function OButton:_touchUpEvent()		
	if(self.touchUpHandler ~= nil) then
		self.touchUpHandler:raiseEvent(nil)
	end
end

function OButton:_clickEvent()
	self:_touchUpEvent()
	
	if(self.clickedHandler ~= nil) then
		self.clickedHandler:raiseEvent(nil)
	end
end

function OButton:_touchDownEvent()	
	if(self.touchDownHandler ~= nil) then
		self.touchDownHandler:raiseEvent(nil)
	end	
end

function OButton:effectPressed(x, y)
	--print("is in region", self:_isInRegion(x, y))
	if self._isDisable == true then return end
	
	if(self:isVisible() and self:getAlpha() > 0 and self:getParent() ~= nil) then
		
		if(self:_isInRegion(x, y)) then
			self._isOnHold = true
			if(not self._isDisable) then
				if(self._isFeedBackZoom) then					
					self:setScale(self.FEEDBACK_ZOOM)					
				elseif(self._isFeedBackAlpha) then
					self:setAlpha(self.FEEDBACK_ALPHA)
				end
								
				self:_touchDownEvent()							
			end
		else
			self._isOnHold = false
		end
		return self._isOnHold
	end	
end

function OButton:effectMoved(x, y)
	if(self:isVisible() and self:getAlpha() > 0 and self:getParent() ~= nil) then
		if(not self:_isInRegion(x, y) and self._isOnHold) then
			self._isOnHold = false
			if(self._isFeedBackZoom) then
				self:setScale(self._normalfzoom)
			elseif(self._isFeedBackAlpha) then
				self:setAlpha(self._normalfalpha)
			end
						
			self:_touchUpEvent()			
		end		
	end
end

function OButton:effectReleased(x, y)
	if(self:isVisible() and self:getAlpha() > 0 and self:getParent() ~= nil) then
		if(self._isOnHold) then
			self:_clickEvent()
			
			if(self._isFeedBackZoom) then
				self:setScale(self._normalfzoom)
			elseif(self._isFeedBackAlpha) then
				self:setAlpha(self._normalfalpha)
			end
		end		
	end
	self._isOnHold = false
end

-- x and y are global coordinates
function OButton:_isInRegion(x, y)	
	if(self._aabb ~= nil) then
		local localx, localy = self:globalToLocal(x, y)
		return self._aabb:contains(localx, localy)		
	else	
		return self:hitTestPoint(x, y)
	end	
end

function OButton:isOnHold()
	return self._isOnHold
end

function OButton:handleInput(input)
	local touchStates = input:getTouchStates()
	
	if(touchStates.size == 0) then
		return
	end
		
	local touch = touchStates[1]	
	if(touch.state == TouchHandler.TOUCH_DOWN) then						
		self:effectPressed(touch.x, touch.y)									
	elseif(touch.state == TouchHandler.TOUCH_MOVED) then				
		self:effectMoved(touch.x, touch.y)						
	elseif(touch.state == TouchHandler.TOUCH_UP) then				
		self:effectReleased(touch.x, touch.y)		
	end		
end