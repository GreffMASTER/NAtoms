enet = require "enet"

enethost = nil
enetclient = nil
hostevent = nil
clientpeer = nil
ready = false
connected = false

players = {}

local networkstate = {}

networkstate.mode = nil

function networkstate.init()
    if(_NAHostIP ~= nil) then
        love.graphics.setBackgroundColor(0.25,0.25,0.25)
        print("Initiating on ".._NAHostIP)
        _CAState.printmsg("Hosting Server on IP: ".._NAHostIP,4)
        enethost = enet.host_create(_NAHostIP,4)

        enetclient = enet.host_create()
            clientpeer = enetclient:connect(_NAHostIP)

        mode = "_NAServer"

    elseif(_NAServerIP ~= nil) then

        print("Connecting to ".._NAServerIP)
        _CAState.printmsg("Connecting to: ".._NAServerIP,30)
        enetclient = enet.host_create()
        clientpeer = enetclient:connect(_NAServerIP)
        mode = "_NAClient"

    end
end

function networkstate.update(dt)
    if(mode == "_NAServer") then
        ServerThinker()
    end
	ClientThinker()
end

function networkstate.draw()
    for i,p in ipairs(players) do
        if(p~=nil) then
            love.graphics.print("Player "..i..": "..p[1].." "..tostring(p[2]),10,i*20)
        else
            love.graphics.print("Player "..i..": None",10,(i*20)+10)
        end
    end
	love.graphics.print("Press enter to switch your ready state",0,0)
end

function networkstate.keypressed(key)
    if(key == "return") then
	    ready = not ready
		if(ready == true) then
		    clientpeer:send("imready")
		else
		    clientpeer:send("imnotready")
		end
    end
end

function networkstate.mousepressed(x,y,button)
end

function networkstate.mousereleased(x,y,button)
end

function ServerThinker()

	hostevent = enethost:service(30)
	
	if hostevent then
		print("Server detected message type: " .. hostevent.type)
		if hostevent.type == "connect" then 
			print(hostevent.peer, "connected.")
            players[hostevent.peer:index()] = {tostring(hostevent.peer),false}
            enethost:broadcast(playerListToString(players))
			enethost:broadcast("CONN|"..tostring(hostevent.peer).."|END")
		end
        if hostevent.type == "disconnect" then
            print(hostevent.peer, "disconnected.")
            players[hostevent.peer:index()] = nil
            enethost:broadcast(playerListToString(players))
			enethost:broadcast("DISCONN|"..tostring(hostevent.peer).."|END")
        end
		if hostevent.type == "receive" then
			print("Server received message: ", hostevent.data, hostevent.peer)
            if(hostevent.data=="imready") then
                players[hostevent.peer:index()][2] = true
				enethost:broadcast("READY|"..tostring(hostevent.peer).."|true|END")
                enethost:broadcast(playerListToString(players))
            end
            if(hostevent.data=="imnotready") then
                players[hostevent.peer:index()][2] = false
				enethost:broadcast("READY|"..tostring(hostevent.peer).."|false|END")
                enethost:broadcast(playerListToString(players))
            end
		end
	end
end



function ClientThinker()

    clientevent = enetclient:service(30)

    if clientevent then
        print("Client detected message type: " .. clientevent.type)
        if clientevent.type == "connect" then
		    connected = true
            _CAState.printmsg("Successfully connected to the game.",4)
        end
		if clientevent.type == "disconnect" then
		    if(connected==false) then
		        love.window.showMessageBox("Connection error", "Could not connect to the server", "error")
			else
			    love.window.showMessageBox("Connection error", "Disconnected from server", "error")
			end
            love.event.quit()
        end
        if clientevent.type == "receive" then
			print("Client received message: ", clientevent.data, clientevent.peer)
            packet = packetStringDecode(clientevent.data)
			if(packet[1]=="PLYRS") then
				if(mode~="_NAServer") then
					players = playerListPacketToArray(packet)
				end
			end
			if(packet[1]=="CONN") then
			    _CAState.printmsg(packet[2].." connected to the game.",4)
			end
			if(packet[1]=="DISCONN")then
			    _CAState.printmsg(packet[2].." disconnected from the game.",4)
			end
			if(packet[1]=="READY") then
			    if(packet[3]=="true") then
			        _CAState.printmsg(packet[2].." is ready.",4)
				elseif(packet[3]=="false") then
				    _CAState.printmsg(packet[2].." is not ready.",4)
			    end
			end
		end
    end
end

function packetStringDecode(str)
    packet = {}
    arr = string.explode(str,"|")
	if(arr[1]=="PLYRS") then
        packet = {arr[1],arr[2],arr[3],{}}
        for i=1,#arr-3 do
            table.insert(packet[4],arr[i+3])
        end
	elseif(arr[1]=="READY") then
	    packet = {arr[1],arr[2],arr[3]}
	elseif(arr[1]=="CONN") then
	    packet = {arr[1],arr[2]}
	elseif(arr[1]=="DISCONN") then
	    packet = {arr[1],arr[2]}
	end
    return packet
end

function playerListToString(plyrs)
    out = "PLYRS|"
    out = out.."2|"
    out = out..tostring(table.getn(plyrs)).."|"
    for i,p in ipairs(plyrs) do
        if(p~=nil) then
            out = out..p[1].."|"..tostring(p[2]).."|"
        else
            out = out.."None|false|"
        end
    end
    out = out.."END"
    return out
end

function playerListPacketToArray(packet)
    arr = {}
    if(packet[1]=="PLYRS") then
        elements= packet[2]
        count = packet[3]
        for i=1,count do
            arr[i] = {packet[4][i*2-1],packet[4][i*2]}
        end
    end
    return arr
end

function string.explode(str, div)
    assert(type(str) == "string" and type(div) == "string", "invalid arguments")
    local o = {}
    while true do
        local pos1,pos2 = str:find(div)
        if not pos1 then
            o[#o+1] = str
            break
        end
        o[#o+1],str = str:sub(1,pos1-1),str:sub(pos2+1)
    end
    return o
end

return networkstate