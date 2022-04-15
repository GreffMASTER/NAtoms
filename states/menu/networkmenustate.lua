local networkmenustate = {}

local ready = false

function networkmenustate.init()
    net.init()
    if(net.mode=="Server") then
        -- set background color to gray to tell apart which window is server
        love.graphics.setBackgroundColor(0.25,0.25,0.25)
    end
end

function networkmenustate.update(dt)
    if(net.mode == "Server") then
        net.ServerThinker(dt)
    end
	net.ClientThinker(dt)
end

function networkmenustate.draw()
    -- draw player list
    for i,p in ipairs(net.players) do
        if(p~=nil) then
            love.graphics.print("Player "..p[1]..": "..p[2].." "..tostring(p[3]),10,i*20)
        end
    end

	love.graphics.print("Press enter to switch your ready state",10,love.graphics.getHeight()-20)
end

function networkmenustate.keypressed(key)
    if(key == "return") then -- press enter to toggle if ready
	    ready = not ready
		if(ready == true) then
		    net.clientpeer:send("imready")
		else
		    net.clientpeer:send("imnotready")
		end
    end
end

function networkmenustate.mousepressed(x,y,button)
end

function networkmenustate.mousereleased(x,y,button)
end

function networkmenustate.quit()
    net.clientpeer:disconnect_now()
    if(net.mode=="Server") then
        net.stopServer()
    end
end

return networkmenustate