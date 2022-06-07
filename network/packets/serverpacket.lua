local sp = {}

-- NOT IN PLAYER LIST

sp.public = {}

function sp.public.AUTH(event,data)
    local str = "NAtoms-v"..net.version.."-"..gmpacket.version.."-ka13"
    local hash = love.data.encode("string", "hex", love.data.hash("sha256", str))

    if data[1] ~= hash then
        event.peer:disconnect_now(99)
        return
    end
    
    if #net.players>=4 then
        event.peer:disconnect_now(9)
        return
    end
    
    if net.ingame then
        event.peer:disconnect_now(10)
        return
    end

    -- remove the peer from the auth list
    for i, v in pairs(net.authList) do
        if v[1] == event.peer then
            table.remove(net.authList, i)
            break
        end
    end
    
    print("Player " .. data[2] .. " authenticated.")
    local newnick = data[2]
    for j=1,4 do
        for i, p in pairs(net.players) do
            if p[2] == newnick then
                newnick = data[2]..tostring(j+1) 
                break
            end
        end
    end

    net.addPlayerToPlayerList( event.peer, newnick )

    if event.peer:index() == 1 then     -- add player 1 to the operator list
        table.insert(net.super,{1,data[2],tostring(event.peer)})
    end

    event.peer:send( gmpacket.encode( "COOLANDGOOD", {event.peer:index(),newnick} ) )

    local tcom = {unpack(net.cmdlst.public)}
    print(net.cmdlst.public[6])
    if event.peer:index() == 1 then     -- give player 1 all the commands
        for k,v in ipairs(net.cmdlst.private) do
            table.insert(tcom, v)
        end
    end

    local cmdstr = ""
    for k,v in ipairs(tcom) do    -- convert the table into string
        cmdstr = cmdstr..v..";"
    end
    event.peer:send( gmpacket.encode( "COMMANDS", {cmdstr} ) )
end

function sp.public.PING(event,data)
    event.peer:send(gmpacket.encode("PONG",{net.version,#net.players,_CAGridW,_CAGridH}))
end

-- IN PLAYER LIST

-- AVATAR STUFF

function sp.AVHASH(event,data)
    hash = data[1]
    if love.filesystem.getInfo("cache/"..hash..".png") then
        local avdata = love.image.newImageData("cache/"..hash..".png")
        local avimage = love.graphics.newImage(avdata)

        for i, p in pairs(net.players) do
            if p[1] == event.peer:index() then
                net.avatars[i] = {avimage,avdata}
                net.enethost:broadcast(gmpacket.encode("AVHASH",{hash,event.peer:index()}))
                break
            end
        end
    else
        event.peer:send(gmpacket.encode("GETAV",{}))   
    end
end

function sp.AVATAR(event,data)
    local avimage
    if data[1] then
        local avdata = stuff.B64ToData(data[1],data[2])
        if avdata:getWidth() == 64 and avdata:getWidth() == 64 then
            local hash = love.data.encode("string", "hex", love.data.hash("sha256",avdata))
            avimage = love.graphics.newImage(avdata)
            love.filesystem.createDirectory("cache")
            avdata:encode("png","cache/"..hash..".png") -- save avatar with its hash as a name
        else
            avimage = false
        end
    else
        avimage = false
    end

    for i, p in pairs(net.players) do
        if p[1] == event.peer:index() then
            if avimage then
                net.avatars[i] = {avimage,avdata}
                net.enethost:broadcast(gmpacket.encode("AVHASH",{hash,event.peer:index()}))
            else
                net.avatars[i] = avimage
            end
            break
        end
    end
end

function sp.GETAV(event,data)
    local avindex = data[1]
    local avdata = net.avatars[avindex][2]
    event.peer:send(gmpacket.encode("AVATAR", {stuff.imgDataToB64(avdata),avdata:getFormat(),avindex}))
end

function sp.GETAVS(event,data)
    for i,av in pairs(net.avatars) do
        if av and av[2] then
            local hash = love.data.encode("string", "hex", love.data.hash("sha256",av[2]))
            event.peer:send(gmpacket.encode("AVHASH",{hash,i}))
        end
    end
end

-- OTHER STUFF

function sp.MESSAGE(event,data)

    local pindex = event.peer:index()
    local pnick = net.getPlayerByIndex(event.peer:index())[2]
    local pip = tostring(event.peer)

    local plyr = {pindex, pnick, pip}
    
    local message = data[1]

    if string.sub(message, 1, 1) == "/" then
        -- commands stuff
        local commandargs = string.explode(string.sub(message, 2, -1)," ")
        local command = commandargs[1]
        table.remove(commandargs,1)

        if net.commands[command] then
            print("Player "..plyr[2].." issued command: "..command)
            local ret = net.commands[command](plyr,commandargs)
            if ret then
                event.peer:send(gmpacket.encode("CHATALERT",{ret}))
            end
        else
            local str = "Command '"..command.."' not found!"
            event.peer:send(gmpacket.encode("CHATALERT",{str}))
        end
    else
        -- send message
        net.enethost:broadcast(gmpacket.encode("MESSAGE",{plyr[2],message}))
    end
end

function sp.READY(event,data)
    local plyrnick
    for i, p in ipairs(net.players) do
        if p[1] == event.peer:index() then
            plyrnick = p[2]
            net.players[i][3] = data[1]
            break
        end
    end

    net.enethost:broadcast(gmpacket.encode("READY", {plyrnick, data[1]}))
    net.enethost:broadcast(gmpacket.encode("PLYRS", net.playerListToArray(net.players)))
end

-- GAMELOGIC STUFF

function sp.DONE(event,data)
    net.playersdone[event.peer:index()] = true
    if net.allPlayersDone() then
        net.enethost:get_peer(net.gamelogic.curplayer):send(gmpacket.encode("YOURMOVE", {}))
    end
end

function sp.CLICKEDTILE(event,data)
    if event.peer:index() == net.gamelogic.curplayer and not net.gamelogic.animplaying then
        for i = 1, #net.playersdone do
            if net.playersdone[i] ~= 0 then
                net.playersdone[i] = false
            end
        end
        net.enethost:broadcast(gmpacket.encode("CLICKON", {data[1], data[2],event.peer:index()}))
    end
end

return sp
