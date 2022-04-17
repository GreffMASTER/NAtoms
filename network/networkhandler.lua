enet = require "enet"
gmpacket = require "network.gmpacket"

local nah = {}

nah.enethost = nil
nah.enetclient = nil
nah.hostevent = nil
nah.clientpeer = nil
nah.mode = nil
nah.connected = false
nah.players = {} -- {peer_index, ip, ready}
nah.playersdone = {}
nah.countdown = 6
nah.ingame = false
nah.allready = false
nah.waiting = false

nah.yourindex = nil
nah.prevplayerturn = nil

-- hooks
nah.gamelogic = nil
nah.netmenu = nil

local function resetPlayersReady(plyrs)
    for k, v in ipairs(plyrs) do
        v[3] = false
    end
end

function nah.init()
    if _NAHostIP ~= nil then
        print("Initiating on " .. _NAHostIP)
        _CAState.printmsg("Hosting Server on IP: " .. _NAHostIP, 4)
        nah.enethost = enet.host_create(_NAHostIP, 5)
        if nah.enethost == nil then -- the server could not create a host
            love.window.showMessageBox("Server Error",
                "Failed to start the server. Perhaps a server is already running on " .. _NAHostIP .. "?", "error")
            love.event.quit()
        end
        nah.enetclient = enet.host_create()
        nah.clientpeer = nah.enetclient:connect(_NAHostIP)
        nah.mode = "Server"
        love.window.setTitle(love.window.getTitle() .. " - Server")
    elseif _NAServerIP ~= nil then
        print("Connecting to " .. _NAServerIP)
        _CAState.printmsg("Connecting to: " .. _NAServerIP, 40)
        nah.enetclient = enet.host_create()
        nah.clientpeer = nah.enetclient:connect(_NAServerIP)
        nah.mode = "Client"
    end
    _NAOnline = true
end

function nah.ServerThinker(dt)

    nah.hostevent = nah.enethost:service(1)

    local allready = true

    for i, v in pairs(nah.players) do
        if not v[3] then
            allready = false
        end
    end

    if allready and #nah.players > 1 and not nah.ingame then

        if nah.countdown > 0 then
            nah.countdown = nah.countdown - dt
            nah.allready = true
        end
        -- every time the countdown increments each second, send a message to all players
        if math.ceil(nah.countdown) ~= math.ceil(nah.countdown - dt) then
            nah.enethost:broadcast(gmpacket.encode("COUNTING", {math.floor(nah.countdown)}))
        end

        if (nah.countdown <= 0) then
            nah.ingame = true
            nah.countdown = 6
            local calc = 0
            for i = 1, #nah.players do
                calc = calc + 2 ^ (nah.players[i][1] - 1)
            end
            -- reset all players ready state
            nah.enethost:broadcast(gmpacket.encode("START", {_CAGridW, _CAGridH, calc}))
        end
    else
        nah.countdown = 6
        nah.allready = false
    end
    
    if nah.hostevent then
        print("Server detected message type: " .. nah.hostevent.type)

        if nah.hostevent.type == "connect" then
            print(nah.hostevent.peer, "connected.")
            if #nah.players>=4 then
                nah.hostevent.peer:disconnect_now(9)
            else
                if not nah.ingame then
                    table.insert(nah.players, nah.hostevent.peer:index(), {nah.hostevent.peer:index(), tostring(nah.hostevent.peer), false})
                    nah.hostevent.peer:send(gmpacket.encode("INDEX", {nah.hostevent.peer:index()}))
                    nah.enethost:broadcast(gmpacket.encode("PLYRS", nah.playerListToArray(nah.players)))
                    nah.enethost:broadcast(gmpacket.encode("CONN", {tostring(nah.hostevent.peer)}))
                else
                    nah.hostevent.peer:disconnect_now(10)
                end
            end
        end

        if nah.hostevent.type == "disconnect" then
            print(nah.hostevent.peer, "disconnected.")
            -- find player with id of peer index
            for i, v in pairs(nah.players) do
                if v[1] == nah.hostevent.peer:index() then
                    table.remove(nah.players, i)
                    break
                end
            end
            nah.enethost:broadcast(gmpacket.encode("PLYRS", nah.playerListToArray(nah.players)))
            nah.enethost:broadcast(
                gmpacket.encode("DISCONN", {tostring(nah.hostevent.peer), nah.hostevent.peer:index()}))
        end

        if nah.hostevent.type == "receive" then
            print("Server received message: ", nah.hostevent.data, nah.hostevent.peer)
            local packet = gmpacket.decode(nah.hostevent.data)

            if packet["name"] == "IMREADY" then
                for i, p in ipairs(nah.players) do
                    if p[1] == nah.hostevent.peer:index() then
                        nah.players[i][3] = true
                        break
                    end
                end
                nah.enethost:broadcast(gmpacket.encode("READY", {tostring(nah.hostevent.peer), true}))
                nah.enethost:broadcast(gmpacket.encode("PLYRS", nah.playerListToArray(nah.players)))
            end

            if packet["name"] == "IMNOTREADY" then
                for i, p in ipairs(nah.players) do
                    if (p[1] == nah.hostevent.peer:index()) then
                        nah.players[i][3] = false
                        break
                    end
                end
                nah.enethost:broadcast(gmpacket.encode("READY", {tostring(nah.hostevent.peer), false}))
                nah.enethost:broadcast(gmpacket.encode("PLYRS", nah.playerListToArray(nah.players)))
            end

            if packet["name"] == "DONE" then
                nah.playersdone[nah.hostevent.peer:index()] = true
                if nah.allPlayersDone() then
                    nah.enethost:get_peer(nah.gamelogic.curplayer):send(gmpacket.encode("YOURMOVE", {}))
                end
            end

            if packet["name"] == "CLICKEDTILE" then
                print("Player " .. nah.hostevent.peer:index() .. " wants to click tile " .. packet["data"][1] .. "," .. packet["data"][2])
                print("Turn for player " .. nah.gamelogic.curplayer)
                if nah.hostevent.peer:index() == nah.gamelogic.curplayer then
                    for i = 1, #nah.playersdone do
                        if nah.playersdone[i] ~= 0 then
                            nah.playersdone[i] = false
                        end
                    end
                    nah.enethost:broadcast(gmpacket.encode("CLICKON", {packet["data"][1], packet["data"][2],
                                                                       nah.hostevent.peer:index()}))
                else
                    print("ILLEGAL MOVE!!!")
                end
            end
        end
    end
end

function nah.ClientThinker(dt)

    nah.clientevent = nah.enetclient:service(1)

    if nah.clientevent then
        print("Client detected message type: " .. nah.clientevent.type)

        if nah.clientevent.type == "connect" then
            nah.connected = true
            _CAState.printmsg("Successfully connected to the game.", 4)
        end

        if nah.clientevent.type == "disconnect" then
            if not nah.connected then
                love.window.showMessageBox("Connection error", "Could not connect to the server.", "error")
            else
                if nah.clientevent.data == 9 then
                    love.window.showMessageBox("Connection error", "Server full.", "error")
                elseif nah.clientevent.data == 10 then
                    love.window.showMessageBox("Connection error", "The game has already started. Please try again later.", "error")
                else
                    love.window.showMessageBox("Connection error", "Disconnected from server. ("..nah.clientevent.data..")", "error")
                end
            end
            love.event.quit()
        end

        if nah.clientevent.type == "receive" then
            print("Client received message: ", nah.clientevent.data, nah.clientevent.peer)
            local packet = gmpacket.decode(nah.clientevent.data)

            if packet["name"] == "PLYRS" then
                if nah.mode ~= "Server" then
                    local playerdata = {}
                    for i = 1, (#packet["data"]) / 3 do
                        table.insert(playerdata, {})
                        for j = 1, 3 do
                            table.insert(playerdata[i], packet["data"][(i - 1) * 3 + j])
                        end
                    end
                    nah.players = playerdata
                end
            end

            if (packet["name"] == "INDEX") then
                nah.yourindex = packet["data"][1]
                nah.netmenu.setBgColor(nah.yourindex)
            end

            if (packet["name"] == "CONN") then
                _CAState.printmsg(packet["data"][1] .. " connected to the game.", 4)
                if not nah.ingame then
                    nah.netmenu.setImage(0)
                end
            end

            if (packet["name"] == "DISCONN") then
                _CAState.printmsg(packet["data"][1] .. " disconnected from the game.", 4)
                if not nah.ingame then
                    nah.netmenu.setImage(0)
                else
                    nah.gamelogic.playertab[packet["data"][2]] = false
                    nah.gamelogic.players = nah.gamelogic.players - 1
                end
            end

            if (packet["name"] == "READY") then
                if not nah.ingame then
                    if (packet["data"][2] == true) then
                        _CAState.printmsg(packet["data"][1] .. " is ready.", 4)
                    elseif (packet["data"][2] == false) then
                        _CAState.printmsg(packet["data"][1] .. " is not ready.", 4)
                    end
                    nah.netmenu.setImage(0)
                end
            end

            if (packet["name"] == "COUNTING") then
                nah.netmenu.setImage(packet["data"][1])
                _CAState.printmsg("Game starting in " .. packet["data"][1] .. " second(s).", 1)
            end

            if (packet["name"] == "START") then
                if nah.mode == "Client" then
                    _CAGridW = packet["data"][1]
                    _CAGridH = packet["data"][2]
                    nah.ingame = true
                end

                nah.setupPlayers(packet["data"][3])
                resetPlayersReady(nah.players)
                _CAState.change("game")
                if nah.gamelogic.curplayer ~= nah.yourindex then
                    nah.waiting = true
                end
            end

            if packet["name"] == "STOP" then
                nah.clientpeer:disconnect()
                love.window.showMessageBox("Connection error", "Server closed!", "error")
                love.event.quit()
            end

            if packet["name"] == "CLICKON" then
                nah.prevplayerturn = nah.gamelogic.curplayer
                nah.gamelogic.clickedTile(packet["data"][1], packet["data"][2])
            end

            if packet["name"] == "YOURMOVE" then
                nah.waiting = false
            end
        end
    end
end

function nah.setupPlayers(value)
    if bit.band(value, 1) == 1 then
        _CAPlayer1 = 1
        nah.playersdone[1] = true
    else
        _CAPlayer1 = 0
        nah.playersdone[1] = 0
    end
    if bit.band(value, 2) == 2 then
        _CAPlayer2 = 1
        nah.playersdone[2] = true
    else
        _CAPlayer2 = 0
        nah.playersdone[2] = 0
    end
    if bit.band(value, 4) == 4 then
        _CAPlayer3 = 1
        nah.playersdone[3] = true
    else
        _CAPlayer3 = 0
        nah.playersdone[3] = 0
    end
    if bit.band(value, 8) == 8 then
        _CAPlayer4 = 1
        nah.playersdone[4] = true
    else
        _CAPlayer4 = 0
        nah.playersdone[4] = 0
    end
end

function nah.allPlayersDone()
    for i = 1, #nah.playersdone do
        if nah.playersdone[i] == false then
            return false
        end
    end
    return true
end

function nah.playerListToArray(plyrs)
    local arr = {}
    for k, v in ipairs(plyrs) do -- { {...}, {...}, {...}, {...} }
        for i, p in ipairs(v) do -- {peer,name,ready}
            table.insert(arr, p)
        end
    end
    return arr
end

function nah.stopServer()
    nah.enethost:flush()
    nah.enethost:broadcast(gmpacket.encode("STOP", {}))
    nah.enethost:flush()
    nah.enethost:destroy()
    nah.enethost = nil
end

function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

return nah
