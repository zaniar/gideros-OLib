MainGameScreen = Core.class(GameScreen)

local WORLD_SIZE = {width = 1600, height = 1200}
local MIN_CAMERA_ZOOM = 0.5

function MainGameScreen:init()	
	application:setBackgroundColor(0x000000)							
	local board = Bitmap.new(Texture.new("space.jpg"))
	local text = TextField.new(TTFont.new("celtic.ttf",14,true),"Camera sample!")	
	text:setPosition(100, 100)
	text:setTextColor(0x00ff00)

	self.camera = Camera.new(WORLD_SIZE.width, WORLD_SIZE.height)							
	self.camera.minZoom = MIN_CAMERA_ZOOM
	self.camera:zoom(1)			
	
	board:addChild(text)
	self.camera:addChild(board)

	self:addChild(self.camera)
end

function MainGameScreen:update(elapsedTime, otherScreenHasFocus, coveredByOtherScreen)
	GameScreen.update(self, elapsedTime, otherScreenHasFocus, coveredByOtherScreen)			

	self.camera:update(elapsedTime)		
end

function MainGameScreen:handleInput(input)			
	local queue = input.queue				
	
	local gesture = nil
	for i=1, queue.size do				
		gesture = queue[i]		
		if(gesture.type == TouchHandler.PINCH) then
			self.camera:setVelocity(0,0)
			self.camera:cancelTween()
		
			local dx = gesture.x1 - gesture.x2
			local dy = gesture.y1 - gesture.y2
			local dxOld = gesture.x1Old - gesture.x2Old
			local dyOld =  gesture.y1Old - gesture.y2Old
			local d = math.sqrt((dx*dx) + (dy*dy))
			local dOld = math.sqrt((dxOld*dxOld) + (dyOld*dyOld))
			local scaleChange = (d - dOld) * 0.01	
			local newScale = self.camera:getScale() + scaleChange								
			self.camera:zoom(newScale)						
		elseif(gesture.type == TouchHandler.FREE_DRAG) then						
			self.camera:setVelocity(0,0)
			self.camera:cancelTween()
			
			local deltaX = (gesture.x - gesture.xOld)
			local deltaY = (gesture.y - gesture.yOld)			
			self.camera:moveCamera(-deltaX, -deltaY)		
		elseif(gesture.type == TouchHandler.FLICK) then						
			self.camera:setVelocity(0, -gesture.deltaY)						
		elseif(gesture.type == TouchHandler.TAP) then			
			self.camera:setVelocity(0,0)
			self.camera:cancelTween()
			
			local wX, wY = self.camera:convertScreenToWorld(gesture.x, gesture.y)	
			
			self:handleTap(gesture.x, gesture.y, wX, wY)
		end 
	end		
end

function MainGameScreen:handleTap(screenX, screenY, worldX, worldY)			
	print("tap : ", screenX, screenY, worldX, worldY)
end