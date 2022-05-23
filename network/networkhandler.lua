enet = require "enet"
gmpacket = require "network.gmpacket"
stuff = require "stuff"

local nah = {}

local kaicon = love.image.newImageData("graphics/icon.png")

nah.sndconn = love.audio.newSource("sounds/natoms/connect.wav","static")
nah.snddisconn = love.audio.newSource("sounds/natoms/disconnect.wav","static")
nah.sndcountdown = love.audio.newSource("sounds/natoms/countdown.wav","static")


nah.version = "a1.2.4"
nah.serverpacket = require "network.packets.serverpacket"
nah.clientpacket = require "network.packets.clientpacket"
nah.commands = require("network.commands")[1]
nah.cmdlst = require("network.commands")[2]

nah.authList = {}

function nah.resetVars()

    nah.enethost = nil
    nah.enetclient = nil
    nah.hostevent = nil
    nah.clientpeer = nil
    nah.mode = nil
    nah.connected = false
    nah.players = {} -- {peer_index, ip, ready}
    nah.avatars = {false,false,false,false}
    nah.playersdone = {}
    nah.super = {}
    nah.countdown = 6
    nah.ingame = false
    nah.allready = false
    nah.waiting = false
    nah.disqualified = false
    nah.yourindex = nil
    nah.prevplayerturn = nil
    nah.youravatar = nil
    nah.urav = nil
    nah.startplayer = 1
    nah.chatlog = {}
    nah.commandlist = {}
    -- hooks
    nah.gamelogic = nil
    nah.netmenu = nil
end

function nah.resetPlayersReady(plyrs)
    for k, v in ipairs(plyrs) do
        v[3] = false
    end
end

function nah.addPlayerToPlayerList(p,nick)
    table.insert(nah.players, p:index(), {p:index(), nick, false})
    nah.enethost:broadcast(gmpacket.encode("PLYRS", nah.playerListToArray(nah.players)))
    nah.enethost:broadcast(gmpacket.encode("CHATALERT",{nick.." connected to the game."}))
    nah.enethost:broadcast(gmpacket.encode("CONN", {nick}))
end

function nah.getPlayerByIndex(index)
    for i, p in ipairs(nah.players) do
        if p[1] == index then
            return p
        end
    end
end

function nah.getPlayerByNick(nick)
    for i, p in ipairs(nah.players) do
        if p[2] == nick then
            return p
        end
    end
end

function nah.disconnect()
    _CAState.printmsg("Disconnecting...", 3)
    if nah.mode == "Server" then
        nah.stopServer()
    end
    if nah.mode == "Client" then
        nah.clientpeer:disconnect_now()
        _NAOnline = false
    end
    love.window.setTitle("KleleAtoms 1.3 (NAtoms)")
    love.window.setIcon(kaicon)
    _CAState.change("menu")
end

function nah.init()
    nah.resetVars()
    if _NAHostIP ~= nil then
        if nah.startServer() then
            nah.mode = "Server"
        else
            return false
        end
    elseif _NAServerIP ~= nil then

        print("Connecting to " .. _NAServerIP..":".._NAPort)
        _CAState.printmsg("Connecting to: " .. _NAServerIP..":".._NAPort, 40)

        nah.enetclient = enet.host_create()
        nah.clientpeer = nah.enetclient:connect(_NAServerIP..":".._NAPort)
        nah.mode = "Client"
    end

    if love.filesystem.getInfo("avatar.png") then 
        nah.urav = love.image.newImageData("avatar.png")
        if nah.urav:getWidth() == 64 and nah.urav:getWidth() == 64 then
            nah.youravatar = love.graphics.newImage(nah.urav)
        else
            print("Avatar must be 64x64! Resetting to default avatar...")
            nah.urav = nil
            nah.youravatar = love.graphics.newImage("graphics/natoms/defaultav.png")
        end
    else
        print("Avatar not found! Resetting to default avatar...")
        nah.youravatar = love.graphics.newImage("graphics/natoms/defaultav.png")
    end
    _NAOnline = true
end

function nah.startServer()
    print("Initiating on " .. _NAHostIP..":".._NAPort)
    _CAState.printmsg("Hosting Server on IP: " .. _NAHostIP..":".._NAPort, 4)

    if _NAHostIP == "localhost" then
        nah.enethost = enet.host_create("*:".._NAPort, 5)
    else
        nah.enethost = enet.host_create(_NAHostIP..":".._NAPort, 5)
    end

    if nah.enethost == nil then -- the server could not create a host
        love.window.showMessageBox("Server Error","Failed to start the server. Perhaps a server is already running on " .. _NAHostIP .. "?", "error")
        _CAState.printmsg("",0)
        _CAState.change("menu")
        return false
    end

    nah.enetclient = enet.host_create()
    nah.clientpeer = nah.enetclient:connect(_NAHostIP..":".._NAPort)
    return true
end

function nah.stopServer()
    if nah.enethost then
        -- disconnect all peers
        for i=1,4 do
            if nah.enethost:get_peer(i) then
                nah.enethost:get_peer(i):disconnect_now(100)
            end
        end
        nah.enethost:flush()
        nah.enethost:destroy()
        nah.enethost = nil
    end
    love.audio.play(nah.snddisconn)
    nah.enetclient = nil
    _NAOnline = false
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
            nah.enethost:broadcast(gmpacket.encode("CHATALERT",{"Game starting in " .. math.floor(nah.countdown) .. " second(s)."}))
        end

        if (nah.countdown <= 0) then
            if #nah.players < 2 then return end
            nah.ingame = true
            nah.countdown = 6
            local calc = 0
            for i = 1, #nah.players do
                calc = calc + 2 ^ (nah.players[i][1] - 1)
            end
            local curplayer = nah.startplayer
            if nah.startplayer == "random" then
                curplayer = nah.players[love.math.random(1,#nah.players)][1]
            end
            while not nah.getPlayerByIndex(curplayer) do
                curplayer = curplayer + 1
                if curplayer > 4 then
                    curplayer = 1
                end
            end
            -- reset all players ready state
            nah.enethost:broadcast(gmpacket.encode("START", {_CAGridW, _CAGridH, calc, curplayer}))
        end
    else
        nah.countdown = 6
        nah.allready = false
    end

    if nah.authList then
        for i, v in pairs(nah.authList) do
            v[2] = v[2] - dt
            if v[2]<=0 then
                v[1]:disconnect_now(99)
                table.remove(nah.authList, i)
            end
        end
    end
    
    while nah.hostevent do
        print("Server detected message type: " .. nah.hostevent.type)

        if nah.hostevent.type == "connect" then
            print(nah.hostevent.peer, "connected.")
            table.insert(nah.authList, {nah.hostevent.peer,5})
        end

        if nah.hostevent.type == "disconnect" then

            print(nah.hostevent.peer, "disconnected.")
            local pnick
            -- find player with id of peer index
            for i, v in pairs(nah.players) do
                if v[1] == nah.hostevent.peer:index() then
                    pnick = v[2]
                    table.remove(nah.players, i)
                    nah.avatars[i] = false
                    break
                end
            end

            if nah.ingame then
                nah.playersdone[nah.hostevent.peer:index()] = 0
                if nah.gamelogic.curplayer == nah.hostevent.peer:index() then
                    local nextp = nah.hostevent.peer:index() + 1
                    while nah.playersdone[nextp] == 0 do
                        nextp = nextp + 1
                        if nextp > 4 then nextp = 1 end
                    end
                    nah.enethost:get_peer(nextp):send(gmpacket.encode("YOURMOVE", {}))
                end
            end
            nah.enethost:broadcast(gmpacket.encode("PLYRS", nah.playerListToArray(nah.players)))
            nah.enethost:broadcast(gmpacket.encode("DISCONN", {pnick, nah.hostevent.peer:index()}))
            nah.enethost:broadcast(gmpacket.encode("CHATALERT",{pnick.." disconnected from the game."}))
        end

        if nah.hostevent.type == "receive" then
            print("Server received message: ", nah.hostevent.data, nah.hostevent.peer)
            local packet = gmpacket.decode(nah.hostevent.data)
            

            if packet then

                local byplayer = false

                for i, v in pairs(nah.players) do
                    if v[1] == nah.hostevent.peer:index() then
                        print("send by player")
                        byplayer = true
                        break
                    end
                end

                print(nah.serverpacket.public)
                if nah.serverpacket.public[packet["name"]] then
                    nah.serverpacket.public[packet["name"]](nah.hostevent,packet["data"])
                end

                if byplayer then -- allow only from players on the player list

                    if nah.serverpacket[packet["name"]] then
                        nah.serverpacket[packet["name"]](nah.hostevent,packet["data"])
                    end

                end -- end of playertab check
            end
        end
        nah.hostevent = nah.enethost:service()
    end
end

function nah.ClientThinker(dt)

    nah.clientevent = nah.enetclient:service(1)

    while nah.clientevent do
        print("Client detected message type: " .. nah.clientevent.type)

        if nah.clientevent.type == "connect" then
            local str = "NAtoms-v"..nah.version.."-"..gmpacket.version.."-ka13"
            local hash = love.data.encode("string", "hex", love.data.hash("sha256", str))
            nah.clientpeer:send(gmpacket.encode("AUTH", {hash,_NAPlayerNick}))
        end

        if nah.clientevent.type == "disconnect" then
            love.audio.play(nah.snddisconn)
            if not nah.connected then
                if nah.clientevent.data == 99 then
                    love.window.showMessageBox("Connection error", "The server is running on a different version. Consider updating your game.", "error")
                elseif nah.clientevent.data == 9 then
                    love.window.showMessageBox("Connection error", "Server full.", "error")
                elseif nah.clientevent.data == 10 then
                    love.window.showMessageBox("Connection error", "The game has already started. Please try again later.", "error")
                else
                    love.window.showMessageBox("Connection error", "Could not connect to the server.", "error")
                end
            else
                if nah.clientevent.data == 8 then
                    love.window.showMessageBox("Connection error", "You have been kicked from the server!", "error")
                elseif nah.clientevent.data == 100 then
                    love.window.showMessageBox("Connection error", "Server closed!", "error")
                else
                    love.window.showMessageBox("Connection error", "Disconnected from server. ("..nah.clientevent.data..")", "error")
                end
            end
            _NAOnline = false
            _CAState.change("menu")
        end

        if nah.clientevent.type == "receive" then
            print("Client received message: ", nah.clientevent.data, nah.clientevent.peer)

            local packet = gmpacket.decode(nah.clientevent.data)
            if packet == nil then print("GOT NIL!!!!!!!!") end
            if packet then
                if nah.clientpacket[packet["name"]] then
                    nah.clientpacket[packet["name"]](nah.clientevent,packet["data"])
                end
            end
        end
        nah.clientevent = nah.enetclient:service()
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

return nah
