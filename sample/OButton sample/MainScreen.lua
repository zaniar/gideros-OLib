MainScreen = Core.class(GameScreen)

function MainScreen:init()		
	self._btnYes = OButton.new(Texture.new("btn_yes.png", true))
	self._btnYes:setAnchorPoint(.5, .5)
	self._btnYes:setFeedBackZoom()
	self._btnYes:setPosition(100, 100)
	self._btnYes.clickedHandler:addEventHandler(self._onClickBtn, {self, "yes"})	

	self._btnNo = OButton.new(Texture.new("btn_no.png", true))
	self._btnNo:setAnchorPoint(.5, .5)
	self._btnNo:setFeedBackZoom()
	self._btnNo.clickedHandler:addEventHandler(self._onClickBtn, {self, "no"})
	self._btnNo:setPosition(200, 100)	
		
	self._buttonList = {}
	table.insert(self._buttonList, self._btnYes)
	table.insert(self._buttonList, self._btnNo)
	
	self:addChild(self._btnYes)	
	self:addChild(self._btnNo)		
end

function MainScreen._onClickBtn(sender, event, params)			
	local self = params[1]
	local val = params[2]

	if(params[2] == "yes")	then
		print("btn yes clicked")
	elseif(params[2] == "no") then
		print("btn no clicked")		
	end
end

function MainScreen:handleInput(input)
	local touchStates = input:getTouchStates()
	
	if(touchStates.size == 0) then
		return
	end
	
	for i=1, #self._buttonList do
		self._buttonList[i]:handleInput(input)
	end
end
