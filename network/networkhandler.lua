enet = require "enet"

local nah = {}

nah.enethost = nil
nah.enetclient = nil
nah.hostevent = nil
nah.clientpeer = nil
nah.mode = nil
nah.connected = false
nah.players = {}
nah.countdown = 5

function nah.init()
    if(_NAHostIP ~= nil) then

        print("Initiating on ".._NAHostIP)
        _CAState.printmsg("Hosting Server on IP: ".._NAHostIP,4)
        nah.enethost = enet.host_create(_NAHostIP,4)
        if(nah.enethost==nil) then -- the server could not create a host
            love.window.showMessageBox("Server Error", "Failed to start the server. Perhaps a server is already running on ".._NAHostIP, "error")
            love.event.quit()
        end
        nah.enetclient = enet.host_create()
        nah.clientpeer = nah.enetclient:connect(_NAHostIP)
        nah.mode = "Server"

    elseif(_NAServerIP ~= nil) then

        print("Connecting to ".._NAServerIP)
        _CAState.printmsg("Connecting to: ".._NAServerIP,30)
        nah.enetclient = enet.host_create()
        nah.clientpeer = nah.enetclient:connect(_NAServerIP)
        nah.mode = "Client"

    end
end

function nah.ServerThinker(dt)

	nah.hostevent = nah.enethost:service(30)

    -- check if all players are ready
    local allready = true
    
    for i,v in pairs(nah.players) do
        if(v[3] == false) then
            allready = false
        end
    end

    if(allready and table.getn(nah.players)>1) then
        if(nah.countdown>0) then
            nah.countdown = nah.countdown - dt
        end
        -- every time the countdown increments each second, send a message to all players
        if(math.ceil(nah.countdown) ~= math.ceil(nah.countdown-dt)) then
            nah.enethost:broadcast("COUNTING|"..tostring(math.ceil(nah.countdown)).."|END")
        end
        if(nah.countdown <= 0) then
            nah.enethost:broadcast("START|"..tostring(_CAGridW).."|"..tostring(_CAGridH).."|"..tostring(table.getn(nah.players)).."|END")
        end
    else
        nah.countdown = 5
    end
	
	if nah.hostevent then
		print("Server detected message type: " .. nah.hostevent.type)
		if nah.hostevent.type == "connect" then 
			print(nah.hostevent.peer, "connected.")
            table.insert(nah.players,nah.hostevent.peer:index(),{nah.hostevent.peer:index(),tostring(nah.hostevent.peer),false})
            nah.enethost:broadcast(playerListToString(nah.players))
			nah.enethost:broadcast("CONN|"..tostring(nah.hostevent.peer).."|END")
		end
        if nah.hostevent.type == "disconnect" then
            print(nah.hostevent.peer, "disconnected.")
            -- find player with id of peer index
            for i,v in pairs(nah.players) do
                if(v[1] == nah.hostevent.peer:index()) then
                    table.remove(nah.players,i)
                    break
                end
            end
            nah.enethost:broadcast(playerListToString(nah.players))
			nah.enethost:broadcast("DISCONN|"..tostring(nah.hostevent.peer).."|END")
        end
		if nah.hostevent.type == "receive" then
			print("Server received message: ", nah.hostevent.data, nah.hostevent.peer)
            if(nah.hostevent.data=="imready") then
                for i,p in ipairs(nah.players) do
                    if(p[1]==nah.hostevent.peer:index()) then
                        nah.players[i][3] = true
                        break
                    end
                end
				nah.enethost:broadcast("READY|"..tostring(nah.hostevent.peer).."|true|END")
                nah.enethost:broadcast(playerListToString(nah.players))
            end
            if(nah.hostevent.data=="imnotready") then
                for i,p in ipairs(nah.players) do
                    if(p[1]==nah.hostevent.peer:index()) then
                        nah.players[i][3] = false
                        break
                    end
                end
				nah.enethost:broadcast("READY|"..tostring(nah.hostevent.peer).."|false|END")
                nah.enethost:broadcast(playerListToString(nah.players))
            end
		end
	end
end

function nah.ClientThinker(dt)

    nah.clientevent = nah.enetclient:service(30)

    if nah.clientevent then
        print("Client detected message type: " .. nah.clientevent.type)
        if nah.clientevent.type == "connect" then
		    nah.connected = true
            _CAState.printmsg("Successfully connected to the game.",4)
        end
		if nah.clientevent.type == "disconnect" then
		    if(nah.connected==false) then
		        love.window.showMessageBox("Connection error", "Could not connect to the server", "error")
			else
			    love.window.showMessageBox("Connection error", "Disconnected from server", "error")
			end
            love.event.quit()
        end
        if nah.clientevent.type == "receive" then
			print("Client received message: ", nah.clientevent.data, nah.clientevent.peer)
            local packet = packetStringDecode(nah.clientevent.data)

			if(packet[1]=="PLYRS") then
				if(nah.mode~="Server") then
					nah.players = packet[3]
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
            if(packet[1]=="COUNTING") then
                _CAState.printmsg("Game starting in "..packet[2].." second(s).",1)
            end
            if(packet[1]=="START") then
                _CAGridW = packet[2]
                _CAGridH = packet[3]
                if(nah.players[1]~=nil) then
                    _CAPlayer1 = 1
                else
                    _CAPlayer1 = 0
                end
                if(nah.players[2]~=nil) then
                    _CAPlayer2 = 1
                else
                    _CAPlayer2 = 0
                end
                if(nah.players[3]~=nil) then
                    _CAPlayer3 = 1
                else
                    _CAPlayer3 = 0
                end
                if(nah.players[4]~=nil) then
                    _CAPlayer4 = 1
                else
                    _CAPlayer4 = 0
                end
                _CAState.change("game")
            end
		end
    end
end

function packetStringDecode(str)
    local packet = {}
    arr = string.explode(str,"|")
	if(arr[1]=="PLYRS") then
        local playerdata = {}
        for i=1,(#arr-2)/3 do
            table.insert(playerdata,{})
            for j=1,3 do
                table.insert(playerdata[i],arr[(i-1)*3+j+2])
            end
        end
        packet = {arr[1],tonumber(arr[2]),playerdata}
	elseif(arr[1]=="READY") then
	    packet = {arr[1],arr[2],arr[3]} -- packet_type, ip, ready
	elseif(arr[1]=="CONN") then
	    packet = {arr[1],arr[2]} -- packet_type, ip
	elseif(arr[1]=="DISCONN") then
	    packet = {arr[1],arr[2]} -- packet_type, ip
    elseif(arr[1]=="COUNTING") then
        packet = {arr[1],arr[2]} -- packet_type, counter
	elseif(arr[1]=="START") then
        packet = {arr[1],tonumber(arr[2]),tonumber(arr[3]),tonumber(arr[4])} -- packet_type, x, y, player_count
	end
    return packet
end

function playerListToString(plyrs)
    out = "PLYRS|"
    out = out..tostring(table.getn(plyrs)).."|"
    for i,p in ipairs(plyrs) do
        if(p~=nil) then
            out = out..p[1].."|"..p[2].."|"..tostring(p[3]).."|"
        end
    end
    out = out.."END"
    return out
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

function table.dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end

return nah