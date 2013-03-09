require "box2d"

MainGameScreen = Core.class(GameScreen)

function MainGameScreen:init()				
	self._event = {deltaTime = 0} -- reusable object yang dipake tiap siklus update			
	self._world = b2.World.new(0, 20)	
	
	local debugDraw = b2.DebugDraw.new()
	debugDraw:setFlags(b2.DebugDraw.SHAPE_BIT + b2.DebugDraw.JOINT_BIT)	
	self._world:setDebugDraw(debugDraw)	
	
	local bodyDef = {}
	bodyDef.position = {x = 0, y = 0}
	bodyDef.type = b2.STATIC_BODY
	
	local fixtureDef = {}
	fixtureDef.shape = b2.PolygonShape.new()
	fixtureDef.friction = 1
	fixtureDef.density = 1
	fixtureDef.shape:setAsBox(3000, 10, 3000, 10, 0)
	
	local body = self._world:createBody(bodyDef)						
	body:createFixture(fixtureDef)	
	body:setPosition(-10,200)

	local bodyDef2 = {}
	bodyDef2.position = {x=0, y=0}
	bodyDef2.type = b2.DYNAMIC_BODY
	
	local fixtureDef2 = {}
	fixtureDef2.shape = b2.PolygonShape.new()
	fixtureDef2.friction = 1
	fixtureDef2.density = 1
	fixtureDef2.shape:setAsBox(10, 10, 10, 10, 2)
	
	local body2 = self._world:createBody(bodyDef2)						
	body2:createFixture(fixtureDef2)	
	body2:setPosition(100,0)
	
	self:addChild(debugDraw)
end

function MainGameScreen:update(elapsedTime, otherScreenHasFocus, coveredByOtherScreen)		  	
	GameScreen.update(self, elapsedTime, otherScreenHasFocus, coveredByOtherScreen)			
	
	self._event.deltaTime = elapsedTime			
	self._world:step(1/60, 8, 3) 
end

function MainGameScreen:handleInput(input)				
	local queue = input.queue	
	local gesture = nil
	for i=1, queue.size do				
		gesture = queue[i]			
		if(gesture.type == TouchHandler.PINCH) then					
			local dx = gesture.x1 - gesture.x2
			local dy = gesture.y1 - gesture.y2
			local dxOld = gesture.x1Old - gesture.x2Old
			local dyOld =  gesture.y1Old - gesture.y2Old
			local d = math.sqrt((dx*dx) + (dy*dy))
			local dOld = math.sqrt((dxOld*dxOld) + (dyOld*dyOld))
			local scaleChange = (d - dOld) * 0.01	
			
			print("pinch (distance before, after): ", d, " , ", dOld)			
		elseif(gesture.type == TouchHandler.FREE_DRAG) then														
			local deltaX = (gesture.x - gesture.xOld)
			local deltaY = (gesture.y - gesture.yOld)			
			
			print("free drag (delta X, delta Y) : ", deltaX, " , ", deltaY)
		elseif(gesture.type == TouchHandler.FLICK) then						
			print("flick (vx, vy): ", gesture.deltaX," , ", gesture.deltaY)
		elseif(gesture.type == TouchHandler.TAP) then												
			print("tap (x, y) : ", gesture.x, " , ", gesture.y)			
		elseif(gesture.type == TouchHandler.HOLD) then
			print("hold (x, y) : ", gesture.x, " , ", gesture.y)			
		end 
	end
end