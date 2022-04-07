enet = require "enet"

enethost = nil
enetclient = nil
hostevent = nil
clientpeer = nil
ready = false

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
        _CAState.printmsg("Connecting to: ".._NAServerIP,4)
        enetclient = enet.host_create()
        clientpeer = enetclient:connect(_NAServerIP)
        mode = "_NAClient"

    end
end

function networkstate.update(dt)
    if(mode == "_NAServer") then
        ServerListen()
    elseif(mode == "_NAClient") then
        ClientSend()
    end
end

function networkstate.draw()
    for i,p in ipairs(players) do
        if(p~=nil) then
            love.graphics.print("Player "..i..": "..p[1].." "..tostring(p[2]),10,i*20)
        else
            love.graphics.print("Player "..i..": None",10,(i*20)+10)
        end
    end
end

function networkstate.keypressed(key)
    if(key == "return") then
        if(ready==false) then
            ready = true
            clientpeer:send("imready")
        end
        if(ready==true) then
            ready = false
            clientpeer:send("imnotready")
        end
    end
end

function networkstate.mousepressed(x,y,button)
end

function networkstate.mousereleased(x,y,button)
end

function ServerListen()

	hostevent = enethost:service(100)
	
	if hostevent then
		print("Server detected message type: " .. hostevent.type)
		if hostevent.type == "connect" then 
			print(hostevent.peer, "connected.")
            players[hostevent.peer:index()] = {tostring(hostevent.peer),false}
            _CAState.printmsg(tostring(hostevent.peer).." connected to the game.",4)
            enethost:broadcast(playerListToString(players))
		end
        if hostevent.type == "disconnect" then
            print(hostevent.peer, "disconnected.")
            players[hostevent.peer:index()] = nil
            _CAState.printmsg(tostring(hostevent.peer).." disconnected from the game.",4)
            enethost:broadcast(playerListToString(players))
        end
		if hostevent.type == "receive" then
			print("Received message: ", hostevent.data, hostevent.peer)
            if(hostevent.data=="imraedy") then
                players[hostevent.peer:index()][2] = true
                _CAState.printmsg(tostring(hostevent.peer).." is ready.",4)
                enethost:broadcast(playerListToString(players))
            end
            if(hostevent.data=="imnotready") then
                players[hostevent.peer:index()][2] = false
                _CAState.printmsg(tostring(hostevent.peer).." is not ready.",4)
                enethost:broadcast(playerListToString(players))
            end
		end
	end

    ClientSend()

end



function ClientSend()

    clientevent = enetclient:service(100)

    if clientevent then
        print("Client detected message type: " .. clientevent.type)
        if clientevent.type == "connect" then
            
        end
        if clientevent.type == "receive" then
			print("Received message: ", clientevent.data, clientevent.peer)
            packetStringDecode(clientevent.data)
            if(mode~="_NAServer") then
                players = playerListPacketToArray(packetStringDecode(clientevent.data))
            end
		end
    end
end

function packetStringDecode(str)
    packet = {}
    arr = string.explode(str,"|")
    packet = {arr[1],arr[2],arr[3],{}}
    for i=1,#arr-3 do
        table.insert(packet[4],arr[i+3])
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