local command = {}

local function isAdmin(plyr)
    for i,p in pairs(net.super) do
        if p[1] == plyr[1] and p[2] == plyr[2] and p[3] == plyr[3] then return true end
    end
end

function command.help(plyr,args)
    return "Help message goes here"
end

function command.login(plyr,args)
    if not args[1] or args[1] == "" then return "Usage: /login <password>" end
    if isAdmin(plyr) then return "You are already a server operator" end

    if args[1] == "supersecretpassword" then    -- replace with actual global password variable
        table.insert(net.super,plyr)
        print("Player "..plyr[2].." is now a server operator!")
        return "You are now a server operator!"
    else
        print("Player "..plyr[2].." tried to authenticate with the password: "..args[1])
        return "Incorrect password!"
    end
end

function command.kick(plyr,args)
    local admin
    for i,p in pairs(net.super) do
        if p == plyr then admin = true end
        break
    end

    if not isAdmin(plyr) then return "You don't have access to that command!" end
    if not args[1] or args[1] == "" then return "Usage: /kick <nick>" end
    local target = net.getPlayerByNick(args[1])
    if target then
        net.enethost:get_peer(target[1]):disconnect(8)
        net.enethost:broadcast(gmpacket.encode("MESSAGE",{"Server","Player "..target[2].." has been kicked from the server."}))
    else
        return "Player "..args[1].." not found!"
    end
end

function command.msg(plyr,args)
    if not args[1] or not args[2] or args[2] == "" then return "Usage: /msg <nick> <message>" end
    if args[1] == plyr[2] then return "You can't send a message to yourself!" end

    local target = net.getPlayerByNick(args[1])
    if not target then return "Player "..args[1].." not found!" end
    table.remove(args,1) --remove the target nick from the args table to avoid confusion
    local message = ""
    for i=1, #args do   -- construct the message from argument parts
        message = message..args[i].." "
    end
    net.enethost:get_peer(plyr[1]):send(gmpacket.encode("MESSAGE",{plyr[2].."->"..target[2],message}))
    net.enethost:get_peer(target[1]):send(gmpacket.encode("MESSAGE",{plyr[2].."->"..target[2],message}))
end

function command.forceready(plyr,args)  -- Created by Nightwolf-47
    if not isAdmin(plyr) then return "You don't have access to that command!" end
    for i,p in ipairs(net.players) do
        net.players[i][3] = true
        net.enethost:broadcast(gmpacket.encode("READY", {p[2], true}))
    end
    net.enethost:broadcast(gmpacket.encode("PLYRS", net.playerListToArray(net.players)))
end

return command
