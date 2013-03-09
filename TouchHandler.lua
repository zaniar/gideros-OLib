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

TouchHandler = Core.class(Sprite)

local LAST_STATUS_IDX = 1
local LAST_X_IDX = 2
local LAST_Y_IDX = 3
local STATUS_IDX = 4
local X_IDX = 5
local Y_IDX = 6

local MAX_TOUCH_ID = 2
local MAX_BUF_SIZE = 10
local MIN_FLICK_DELTA = 1 -- 
local MAX_HOLD_RADIUS = 20 -- dalam pixel

local MAX_TAP_TIME = 0.5 --dalam detik, kalau melebihi ini dianggap hold

TouchHandler.PINCH = 0
TouchHandler.TAP = 1
TouchHandler.HOLD = 2
TouchHandler.FLICK = 3
TouchHandler.FREE_DRAG = 4

TouchHandler.TOUCH_DOWN = 0
TouchHandler.TOUCH_UP = 1
TouchHandler.TOUCH_MOVED = 2

function TouchHandler:init(sprite) 		
	
	--queue object event pool(cuman sebagai pengingat doang, gak dipake dalam kode)
	self.PINCH_OBJ = {type = TouchHandler.PINCH, x = 0, y = 0, x1 = 0, y1 = 0, x2 = 0, y2 = 0, x1Old = 0, y1Old = 0, x2Old = 0, y2Old = 0}
	self.FREE_DRAG_OBJ = {type = TouchHandler.FREE_DRAG, x = 0, y = 0, xOld = 0, yOld = 0}
	self.FLICK_OBJ = {type = TouchHandler.FLICK, x = 0, y = 0, deltaX = 0, deltaY = 0}
	self.TAP_OBJ = {type = TouchHandler.TAP, x = 0, y = 0}
	
	--properties
	self.touchesData = {
		-- [id] [last status, last x, last y, status, x, y]
		[1] = {TouchHandler.TOUCH_UP, 0, 0, TouchHandler.TOUCH_UP, 0, 0},
		[2] = {TouchHandler.TOUCH_UP, 0, 0, TouchHandler.TOUCH_UP, 0, 0}
	}
	self.touchDownTime = 0 -- berapa lama satu jari nyentuh screen
	self.numFingerDown = 0 -- ada berapa jari di layar	
	self.checkHold = true
	self.firstTouchOnScreen = {x = 0, y = 0, id = 0} -- kordinat jari pertama yang menekan layar
	self._enabled = false
	self._sprite = sprite		
	
	self:setTouchEnabled(true)		
end

function TouchHandler:initQueue() 
	for i=1, MAX_BUF_SIZE do
		self.bufferq[i] = {}
		self.queue[i] = {}
	end	
end

function TouchHandler:initTouchStates()
	for i=1, MAX_TOUCH_ID do
		self._bufferts[i] = {id = i, x = 0, y = 0, state = TouchHandler.TOUCH_UP}
		self._touchStates[i] = {id = i, x = 0, y = 0, state = TouchHandler.TOUCH_UP}		
	end	
end

function TouchHandler:setTouchEnabled(value)	
	if(self._enabled ~=  value) then
		self._enabled = value
		if(self._enabled) then			
			self._sprite:addEventListener(Event.TOUCHES_BEGIN, self.onTouchesBegin, self)	
			self._sprite:addEventListener(Event.TOUCHES_MOVE, self.onTouchesMove, self)
			self._sprite:addEventListener(Event.TOUCHES_END, self.onTouchesEnd, self)
			self._sprite:addEventListener(Event.TOUCHES_CANCEL, self.onTouchesCancel, self)					
		else			
			self._sprite:removeEventListener(Event.TOUCHES_BEGIN, self.onTouchesBegin, self)	
			self._sprite:removeEventListener(Event.TOUCHES_MOVE, self.onTouchesMove, self)
			self._sprite:removeEventListener(Event.TOUCHES_END, self.onTouchesEnd, self)
			self._sprite:removeEventListener(Event.TOUCHES_CANCEL, self.onTouchesCancel, self)					
		end		
		self:reset()
	end
end

--untuk inisialisasi TouchHandler setelah disable/enable dari luar
function TouchHandler:reset()
	self.touchesData = {
		-- [id] [last status, last x, last y, status, x, y]
		[1] = {TouchHandler.TOUCH_UP, 0, 0, TouchHandler.TOUCH_UP, 0, 0},
		[2] = {TouchHandler.TOUCH_UP, 0, 0, TouchHandler.TOUCH_UP, 0, 0}
	}
	self.touchDownTime = 0 -- berapa lama satu jari nyentuh screen
	self.numFingerDown = 0 -- ada berapa jari di layar	
	self.checkHold = true
	self.firstTouchOnScreen = {x = 0, y = 0, id = 0}; -- kordinat jari pertama yang menekan layar	
	
	--queue gesture
	self.bufferq = {size = 0} --simpenan untuk update berikutnya
	self.queue = {size = 0} --yang bisa dikonsumsi oleh user tiap di update	 
	
	--touch state
	self._bufferts = {size = 0} -- simpenan untuk update berikutnya
	self._touchStates = {size = 0} -- yang bisa dikonsumsi oleh user tiap di update
	--format tiap element touchstate adalah  : id, x, y, state	
	
	self:initQueue()	
	self:initTouchStates()
end

function TouchHandler:getTouchStates()	
	return self._touchStates
end

function TouchHandler:update(event)		
	local tempble = self.queue	
	self.queue = self.bufferq
	self.bufferq = tempble
	self.bufferq.size = 0	
	
	local tempts = self._touchStates
	self._touchStates = self._bufferts
	self._bufferts = tempts
	self._bufferts.size = 0	
	
	if(self.checkHold and self.numFingerDown == 1) then
		self.touchDownTime = self.touchDownTime + event.deltaTime		
		--print("time : ", self.touchDownTime)	
		local firstTouch = self.firstTouchOnScreen
		--print("distance ", distance(firstTouch, self.touchesData[firstTouch.id][X_IDX], self.touchesData[firstTouch.id][Y_IDX]))
		local d = self:_distance(firstTouch, self.touchesData[firstTouch.id][X_IDX], self.touchesData[firstTouch.id][Y_IDX])
		if(d>MAX_HOLD_RADIUS) then
			self.checkHold = false
		end
		if(self.checkHold and self.touchDownTime >= MAX_TAP_TIME) then							
			if(d <= MAX_HOLD_RADIUS) then
				self:hold()		
				self.checkHold = false
			end
		end
	end	
end

function TouchHandler:updateLastTouch(params) 	

	if(params.id > MAX_TOUCH_ID) then
		return
	end

	self.touchesData[params.id][LAST_STATUS_IDX], self.touchesData[params.id][LAST_X_IDX], self.touchesData[params.id][LAST_Y_IDX] = 
		self.touchesData[params.id][STATUS_IDX], self.touchesData[params.id][X_IDX], self.touchesData[params.id][Y_IDX]	
end

function TouchHandler:onTouchesBegin(event)		
	local touch = event.touch	
	
	--print("touch begin", self.numFingerDown)
	
	if(touch.id>MAX_TOUCH_ID) then
		return
	end
	
	--masukin touch id tersebut ke buffer 	
	self:_addToTouchStatesBuffer(touch.id, touch.x, touch.y, TouchHandler.TOUCH_DOWN)
	
	if(self.numFingerDown == 0) then
		self.firstTouchOnScreen.x, self.firstTouchOnScreen.y = touch.x, touch.y		
		self.firstTouchOnScreen.id = touch.id
		self.checkHold = true
	end
		
	self:updateLastTouch(touch)
	self.touchesData[touch.id][STATUS_IDX] = TouchHandler.TOUCH_DOWN
	self.touchesData[touch.id][X_IDX] = touch.x
	self.touchesData[touch.id][Y_IDX] = touch.y		
	
	self.numFingerDown = self.numFingerDown + 1	
	
	if(self.numFingerDown == 2) then		
		self:updateLastTouch(event.allTouches[1])
		self:updateLastTouch(event.allTouches[2])
		self.checkHold = false -- ada dua tangan di layar berarti gak mungkin tap atau hold
	elseif(self.numFingerDown == 1) then
		self.touchDownTime = 0
	end
end

function TouchHandler:onTouchesMove(event)					
	local touch = event.touch	
	
	--print("move", touch.id, touch.x, touch.y)
	
	if(touch.id>MAX_TOUCH_ID) then
		return
	end				
	
	--masukin touch id tersebut ke buffer 	
	self:_addToTouchStatesBuffer(touch.id, touch.x, touch.y, TouchHandler.TOUCH_MOVED)
	
	self:updateLastTouch(touch)
	self.touchesData[touch.id][STATUS_IDX] = TouchHandler.TOUCH_MOVED
	self.touchesData[touch.id][X_IDX] = touch.x
	self.touchesData[touch.id][Y_IDX] = touch.y	
	
	if(self.numFingerDown == 2) then
		self:pinch()
	else
		self:freeDrag(touch)
	end
end

function TouchHandler:onTouchesEnd(event)				
	local touch = event.touch	
	
	--print("touch end", self.numFingerDown, touch.x, touch.y)
	
	if(touch.id > MAX_TOUCH_ID) then
		return
	end
	
	--masukin touch id tersebut ke buffer 	
	self:_addToTouchStatesBuffer(touch.id, touch.x, touch.y, TouchHandler.TOUCH_UP)
	
	--free drag sengaja diperiksa sebelum touchnya di update
	if(self.checkHold == false and self.numFingerDown == 1) then		
		--print("deltax", math.abs(self.touchesData[touch.id][X_IDX] - self.touchesData[touch.id][LAST_X_IDX]))
		--print("deltay", math.abs(self.touchesData[touch.id][Y_IDX] - self.touchesData[touch.id][LAST_Y_IDX]))
		--print("old", self.touchesData[touch.id][LAST_X_IDX], self.touchesData[touch.id][LAST_Y_IDX])
		--print("new", self.touchesData[touch.id][X_IDX], self.touchesData[touch.id][Y_IDX])
		if(math.abs(self.touchesData[touch.id][X_IDX] - self.touchesData[touch.id][LAST_X_IDX]) >= MIN_FLICK_DELTA or 
			math.abs(self.touchesData[touch.id][Y_IDX] - self.touchesData[touch.id][LAST_Y_IDX]) >= MIN_FLICK_DELTA) then					
			--terjadi flick			
			self:flick(touch)			
		end			
	end
	
	self:updateLastTouch(touch)	
	
	self.touchesData[touch.id][STATUS_IDX] = TouchHandler.TOUCH_UP	
	self.touchesData[touch.id][X_IDX] = touch.x
	self.touchesData[touch.id][Y_IDX] = touch.y		
	
	if(self.checkHold and self.touchDownTime < MAX_TAP_TIME and self.numFingerDown == 1) then
		--kalo hold aja udah gak mungkin apalagi tap
		self:tap(touch)		
		--print("tap", self.touchDownTime)		
	end
	
	self.numFingerDown = self.numFingerDown - 1	
end

function TouchHandler:onTouchesCancel(event)	
	print("touch cancel",self.numFingerDown)
	
	if(touch.id > MAX_TOUCH_ID) then
		return
	end
	
	self:updateLastTouch(touch)
	self.touchesData[touch.id][STATUS_IDX] = TouchHandler.TOUCH_UP	
		
	self.numFingerDown = 0	
	for i=1, MAX_TOUCH_ID do
		if(self.touchesData[i][STATUS_IDX] == TouchHandler.TOUCH_DOWN) then
			self.numFingerDown = self.numFingerDown + 1
		end
	end
end

function TouchHandler:pinch()				
	local pobj = self.bufferq[self.bufferq.size + 1]
	pobj.type = TouchHandler.PINCH
	pobj.x, pobj.y = self.touchesData[1][X_IDX], self.touchesData[1][Y_IDX]
	pobj.x1, pobj.y1 = self.touchesData[1][X_IDX], self.touchesData[1][Y_IDX] 
	pobj.x2, pobj.y2 = self.touchesData[2][X_IDX], self.touchesData[2][Y_IDX]
	pobj.x1Old, pobj.y1Old = self.touchesData[1][LAST_X_IDX], self.touchesData[1][LAST_Y_IDX]
	pobj.x2Old, pobj.y2Old = self.touchesData[2][LAST_X_IDX], self.touchesData[2][LAST_Y_IDX]			
	self.bufferq.size = self.bufferq.size + 1 --add pinch ke bufferq 		
	--[[
	print("pinch", self.touchesData[1][X_IDX], self.touchesData[1][Y_IDX], 
					self.touchesData[2][X_IDX], self.touchesData[2][Y_IDX],
					self.touchesData[1][LAST_X_IDX], self.touchesData[1][LAST_Y_IDX])
					self.touchesData[2][LAST_X_IDX], self.touchesData[2][LAST_Y_IDX])	
	--]]
	--print("pinch_1", self.touchesData[1][X_IDX], self.touchesData[1][Y_IDX], self.touchesData[1][LAST_X_IDX], self.touchesData[1][LAST_Y_IDX])
	--print("pinch_2", self.touchesData[2][X_IDX], self.touchesData[2][Y_IDX], self.touchesData[2][LAST_X_IDX], self.touchesData[2][LAST_Y_IDX])
	
end

function TouchHandler:freeDrag(touch)
	local fobj = self.bufferq[self.bufferq.size + 1]
	fobj.type = TouchHandler.FREE_DRAG
	fobj.x, fobj.y = self.touchesData[touch.id][X_IDX], self.touchesData[touch.id][Y_IDX] 
	fobj.xOld, fobj.yOld = self.touchesData[touch.id][LAST_X_IDX], self.touchesData[touch.id][LAST_Y_IDX]
	self.bufferq.size = self.bufferq.size + 1 --add free drag ke bufferq 		
end

function TouchHandler:flick(touch)
	local flobj = self.bufferq[self.bufferq.size + 1]
	flobj.type = TouchHandler.FLICK
	flobj.x, flobj.y = self.touchesData[touch.id][X_IDX], self.touchesData[touch.id][Y_IDX]
	flobj.deltaX = self.touchesData[touch.id][X_IDX] - self.touchesData[touch.id][LAST_X_IDX]
	flobj.deltaY = self.touchesData[touch.id][Y_IDX] - self.touchesData[touch.id][LAST_Y_IDX]
	self.bufferq.size = self.bufferq.size + 1 --add flick ke bufferq	
	
	--print("flick")
end

function TouchHandler:tap(touch)
	local tpobj = self.bufferq[self.bufferq.size + 1]
	tpobj.type = TouchHandler.TAP
	tpobj.x, tpobj.y = self.touchesData[touch.id][X_IDX], self.touchesData[touch.id][Y_IDX]
	self.bufferq.size = self.bufferq.size + 1 --add tap ke bufferq
end

function TouchHandler:hold()	
	--print("hold")

	local hobj = self.bufferq[self.bufferq.size + 1]
	hobj.type = TouchHandler.HOLD
	hobj.x, hobj.y = self.firstTouchOnScreen.x, self.firstTouchOnScreen.y
end

function TouchHandler:_distance(point1, x, y)
	
	local deltaX = point1.x - x
	local deltaY = point1.y - y
	
	return math.sqrt((deltaX * deltaX) + (deltaY * deltaY))
end

function TouchHandler:_addToTouchStatesBuffer(id, x, y, state)
	if(id > MAX_TOUCH_ID) then
		return
	end
	
	local obuf = nil	
	
	--cari apakah touch id tersebut sudah ada di bufferts sebelumnya
	for i=1, self._bufferts.size do		
		if(self._bufferts[i].id == id) then
			obuf = self._bufferts[i]
			break
		end
	end
		
	if(obuf == nil) then
		--touch tersebut belum ada di bufferts
		obuf = self._bufferts[self._bufferts.size + 1]
		self._bufferts.size = self._bufferts.size + 1
	elseif(state == TouchHandler.TOUCH_MOVED) then	
		--jika state yang sekarang move, dan ternyata sudah ada id tersebut di buffer, hiraukan move
		return
	end	
	obuf.id = id
	obuf.x = x
	obuf.y = y
	obuf.state = state		
end