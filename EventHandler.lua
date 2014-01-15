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

EventHandler = Core.class()

--[[
	format parameter func are :
		-sender(who raise the event)
		-event(data about the event)		
		-params(extra data that is sent by the object who receives the event)
--]]

function EventHandler:init(sender)
	self._handler = {}	
	self._sender = sender
end

--func must not nil, params can be nil
function EventHandler:addEventHandler(func, params)
	local newHandler = {}
	newHandler.f = func
	newHandler.params = params
	self._handler[#self._handler + 1] = newHandler

end

function EventHandler:removeEventHandler(func)
	for i=1, #self._handler do
		if(self._handler[i].f == func) then
			table.remove(self._handler, i)			
			break
		end
	end
end

function EventHandler:removeAllEventHandler()
	for i=#self._handler, 1, -1 do
		table.remove(self._handler, i)
	end
end

function EventHandler:raiseEvent(event)		
	for i=1, #self._handler do				
		self._handler[i].f(self._sender, event, self._handler[i].params)		
	end	
end

