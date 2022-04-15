enet = require "enet"
packet = require "network.packet"

local nah = {}

nah.enethost = nil
nah.enetclient = nil
nah.hostevent = nil
nah.clientpeer = nil
nah.mode = nil
nah.connected = false
nah.players = {} -- {peer_index, ip, ready}
nah.countdown = 5
nah.ingame = false

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
    _NAOnline = true
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

    if(allready and table.getn(nah.players)>1 and nah.ingame == false) then
        if(nah.countdown>0) then
            nah.countdown = nah.countdown - dt
        end
        -- every time the countdown increments each second, send a message to all players
        if(math.ceil(nah.countdown) ~= math.ceil(nah.countdown-dt)) then
            nah.enethost:broadcast("COUNTING|"..tostring(math.floor(nah.countdown)).."|END")
        end
        if(nah.countdown <= 0) then
            nah.ingame = true
            nah.countdown = 5
            nah.enethost:broadcast(packet.playerListToConfig(nah.players))
        end
    else
        nah.countdown = 5
    end
	
	if nah.hostevent then
		print("Server detected message type: " .. nah.hostevent.type)
		if nah.hostevent.type == "connect" then 
			print(nah.hostevent.peer, "connected.")
            if(nah.ingame==false) then
                table.insert(nah.players,nah.hostevent.peer:index(),{nah.hostevent.peer:index(),tostring(nah.hostevent.peer),false})
                nah.enethost:broadcast(packet.playerListToString(nah.players))
			    nah.enethost:broadcast("CONN|"..tostring(nah.hostevent.peer).."|END")
            else
                nah.hostevent.peer:send("INGAME|END")
                nah.hostevent.peer:disconnect_now()
            end
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
            nah.enethost:broadcast(packet.playerListToString(nah.players))
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
                nah.enethost:broadcast(packet.playerListToString(nah.players))
            end

            if(nah.hostevent.data=="imnotready") then
                for i,p in ipairs(nah.players) do
                    if(p[1]==nah.hostevent.peer:index()) then
                        nah.players[i][3] = false
                        break
                    end
                end
				nah.enethost:broadcast("READY|"..tostring(nah.hostevent.peer).."|false|END")
                nah.enethost:broadcast(packet.playerListToString(nah.players))
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
            local pckt = packet.stringDecode(nah.clientevent.data)

			if(pckt[1]=="PLYRS") then
				if(nah.mode~="Server") then
					nah.players = pckt[3]
				end
			end

			if(pckt[1]=="CONN") then
			    _CAState.printmsg(pckt[2].." connected to the game.",4)
			end

			if(pckt[1]=="DISCONN")then
			    _CAState.printmsg(pckt[2].." disconnected from the game.",4)
			end

			if(pckt[1]=="READY") then
			    if(pckt[3]=="true") then
			        _CAState.printmsg(pckt[2].." is ready.",4)
				elseif(pckt[3]=="false") then
				    _CAState.printmsg(pckt[2].." is not ready.",4)
			    end
			end

            if(pckt[1]=="COUNTING") then
                _CAState.printmsg("Game starting in "..pckt[2].." second(s).",1)
            end

            if(pckt[1]=="START") then
                print(dump(pckt))
                if(nah.mode=="Client") then
                    _CAGridW = pckt[2]
                    _CAGridH = pckt[3]
                    nah.ingame = true
                end

                nah.setupPlayers(pckt[4])

                _CAState.change("game")
            end

            if(pckt[1]=="STOP") then
                nah.clientpeer:disconnect()
                love.window.showMessageBox("Connection error", "Server closed!", "error")
                love.event.quit()
            end

            if(pckt[1]=="INGAME") then
                love.window.showMessageBox("Connection error", "The game you are trying to connect has already started!", "error")
                love.event.quit()
            end
		end
    end
end

function nah.setupPlayers(value)
    if(bit.band(value,1)==1) then
        _CAPlayer1 = 1
    else
        _CAPlayer1 = 0
    end
    if(bit.band(value,2)==2) then
        _CAPlayer2 = 1
    else
        _CAPlayer2 = 0
    end
    if(bit.band(value,4)==4) then
        _CAPlayer3 = 1
    else
        _CAPlayer3 = 0
    end
    if(bit.band(value,8)==8) then
        _CAPlayer4 = 1
    else
        _CAPlayer4 = 0
    end
end

function nah.stopServer()
    nah.enethost:flush()
    nah.enethost:broadcast("STOP|END")
    nah.enethost:flush()
    nah.enethost:destroy()
    nah.enethost = nil
end


function dump(o)
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