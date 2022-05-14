local command = {}

local serverPassword = "" --Temporary
local ballresponses = {"It is certain.","It is decidedly so.","Without a doubt.",
                        "Yes definitely.","You may rely on it.","As I see it, yes.",
                        "Most likely.","Outlook good.","Yes.","Signs point to yes.",
                        "Reply hazy, try again.","Ask again later.","Better not tell you now.",
                        "Cannot predict now.","Concentrate and ask again.","Don't count on it.",
                        "My reply is no.","My sources say no.","Outlook not so good.","Very doubtful."}

local function isAdmin(plyr)
    for i,p in pairs(net.super) do
        if p[1] == plyr[1] and p[2] == plyr[2] and p[3] == plyr[3] then return true end
    end
end

local function consolePrint(plyr,str)
    net.enethost:get_peer(plyr[1]):send(gmpacket.encode("CHATALERT",{str}))
end

function command.help(plyr,args)
    consolePrint(plyr,"Commands:")
    consolePrint(plyr,"/help - displays this message")
    consolePrint(plyr,"/login <password> - login to be a server operator")
    consolePrint(plyr,"/msg <nick> <message> - send a private message")
    consolePrint(plyr,"/password [password] - set or check admin password")
    consolePrint(plyr,"/kick <nickname> - kick a player")
    consolePrint(plyr,"/forceready - force all players to be ready")
    consolePrint(plyr,"/startplayer [1/2/3/4/random] - set starting player")
    consolePrint(plyr,"/magic8ball <text> - ask a magic 8 ball")
    consolePrint(plyr,"/clearchat - clears the chat for all players")
end

function command.password(plyr,args) -- Created by Nightwolf-47
    if not isAdmin(plyr) then return "You don't have access to that command!" end
    if not args[1] or args[1] == "" then return "Password: "..serverPassword end
    serverPassword = args[1]
    return "Admin password changed."
end

function command.startplayer(plyr,args)
    if not args[1] or args[1] == "" then return "Current value: "..net.startplayer end
    if not isAdmin(plyr) then return "You can not modify this CVar!" end
    if tonumber(args[1]) then
        local pnum = tonumber(args[1])
        if pnum >= 1 and pnum <= 4 then
            net.startplayer = pnum
            return "Starting player set to "..args[1].."."
        else
            return "Invalid player number "..pnum
        end
    elseif args[1]:lower() == "random" then
        net.startplayer = "random"
        return "Starting player set to random."
    else
        return "Usage: /startplayer [1/2/3/4/random]"
    end
end

function command.login(plyr,args)
    if not args[1] or args[1] == "" then return "Usage: /login <password>" end
    if isAdmin(plyr) then return "You are already a server operator." end

    if args[1] == serverPassword then    -- replace with actual global password variable
        for k,v in pairs(net.super) do
            consolePrint(plyr,plyr[2].." is now a server operator!")
        end
        table.insert(net.super,plyr)
        print("Player "..plyr[2].." is now a server operator!")
        return "You are now a server operator!"
    else
        print("Player "..plyr[2].." tried to authenticate with the password: "..args[1])
        return "Incorrect password!"
    end
end

function command.kick(plyr,args)
    if not isAdmin(plyr) then return "You don't have access to that command!" end
    if not args[1] or args[1] == "" then return "Usage: /kick <nick>" end
    local target = net.getPlayerByNick(args[1])
    if target[1] == 1 then return "You can't kick the host from the game!" end
    if target[2] == plyr[2] then return "You can't kick yourself from the game!" end
    if target then
        net.enethost:get_peer(target[1]):disconnect(8)
        net.enethost:broadcast(gmpacket.encode("CHATALERT",{"Player "..target[2].." has been kicked from the server."}))
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
    return "Forced all players to be Ready."
end

function command.magic8ball(plyr,args)
    if not args[1] or args[1] == "" then return "Usage: /magic8ball <text>" end
    local message = ""
    for i=1, #args do   -- construct the message from argument parts
        message = message..args[i].." "
    end
    net.enethost:broadcast(gmpacket.encode("MESSAGE",{plyr[2],"My Magic 8 Ball, "..message}))
    local response = ballresponses[math.random(1,#ballresponses)]
    net.enethost:broadcast(gmpacket.encode("MESSAGE",{"Magic8Ball",response}))
end

function command.clearchat(plyr,args)
    if not isAdmin(plyr) then return "You don't have access to that command!" end
    net.enethost:broadcast(gmpacket.encode("CLEARCHAT",{}))
    return "Chat cleared."
end

return command
