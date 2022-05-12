local cp = {}

function cp.COOLANDGOOD(event,data)
    net.connected = true
    net.yourindex = data[1]
    net.netmenu.setBgColor(net.yourindex)
    net.netmenu.playMusic()
    if net.urav then
        net.clientpeer:send(gmpacket.encode("AVHASH", {love.data.encode("string", "hex", love.data.hash("sha256",net.urav))}))
    else
        net.clientpeer:send(gmpacket.encode("AVATAR", {false}))
    end
    net.clientpeer:send(gmpacket.encode("GETAVS", {}))
    _CAState.printmsg("Successfully connected to the game.", 4)
end

-- AVATAR STUFF

function cp.GETAV(event,data)
    net.clientpeer:send(gmpacket.encode("AVATAR", {stuff.imgDataToB64(net.urav),net.urav:getFormat()}))
end



function cp.AVHASH(event,data)
    local hash = data[1]
    local peerindex = data[2]
    if peerindex ~= net.yourindex then
        if love.filesystem.getInfo("cache/"..hash..".png") then
            local avdata = love.image.newImageData("cache/"..hash..".png")
            local avimage = love.graphics.newImage(avdata)
            net.avatars[peerindex] = {avimage,avdata}
        else
            net.clientpeer:send(gmpacket.encode("GETAV", {peerindex}))
        end
    end
end

function cp.AVATAR(event,data)
    local avindex = data[3]
    if data[1] then
        local avdata = stuff.B64ToData(data[1],data[2])
        if avdata:getWidth() == 64 and avdata:getWidth() == 64 then
            local hash = love.data.encode("string", "hex", love.data.hash("sha256",avdata))
            local avimage = love.graphics.newImage(avdata)

            love.filesystem.createDirectory("cache")
            avdata:encode("png","cache/"..hash..".png")
        else
            avimage = false
        end
    else
        avimage = false
    end
    if avimage then
        net.avatars[avindex] = {avimage,avdata}
    else
       net.avatars[avindex] = avimage
    end
end

-- OTHER STUFF

function cp.MESSAGE(event,data)
    local plyrnick = data[1]
    local message = data[2]
    _CAState.printmsg("<"..plyrnick.."> "..message,3)
end

function cp.CHATALERT(event,data)
    _CAState.printmsg(data[1],3)
end

function cp.PLYRS(event,data)
    if net.mode ~= "Server" then
        local playerdata = {}
        for i = 1, (#data) / 3 do
            table.insert(playerdata, {})
            for j = 1, 3 do
                table.insert(playerdata[i], data[(i - 1) * 3 + j])
            end
        end
        net.players = playerdata
    end
end

function cp.CONN(event,data)
    _CAState.printmsg(data[1] .. " connected to the game.", 4)
    love.audio.play(net.sndconn)
    if not net.ingame then
        net.netmenu.setImage(0)
    end
end

function cp.DISCONN(event,data)
    _CAState.printmsg(data[1] .. " disconnected from the game.", 4)
    love.audio.play(net.snddisconn)
    if not net.ingame then
        net.netmenu.setImage(0)
    else
        if net.gamelogic.playertab[data[2]] then
            net.gamelogic.playertab[data[2]] = false
            net.gamelogic.players = net.gamelogic.players - 1
        end
    end
end

function cp.READY(event,data)
    if not net.ingame then
        if data[2] then
            _CAState.printmsg(data[1] .. " is ready.", 4)
            if net.getPlayerByNick(data[1])[2] == _NAPlayerNick then net.netmenu.ready = true end
        elseif not data[2] then
            _CAState.printmsg(data[1] .. " is not ready.", 4)
            if net.getPlayerByNick(data[1])[2] == _NAPlayerNick then net.netmenu.ready = false end
        end
        
        net.netmenu.setImage(0)
    end
end

function cp.COUNTING(event,data)
    net.netmenu.setImage(data[1])
    _CAState.printmsg("Game starting in " .. data[1] .. " second(s).", 1)
    love.audio.play(net.sndcountdown)
end

function cp.START(event,data)
    if net.mode == "Client" then
        _CAGridW = data[1]
        _CAGridH = data[2]
        net.ingame = true
    end

    net.setupPlayers(data[3])
    net.resetPlayersReady(net.players)
    net.netmenu.stopMusic()
    _CAState.change("game")
    if net.gamelogic.curplayer ~= net.yourindex then
        net.waiting = true
    end
end

-- GAMELOGIC STUFF

function cp.CLICKON(event,data)
    net.prevplayerturn = net.gamelogic.curplayer
    net.waiting = true
    net.gamelogic.clickedTile(data[1], data[2])
end

function cp.YOURMOVE(event,data)
    net.waiting = false
end

return cp
