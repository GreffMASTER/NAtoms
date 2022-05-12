local lobbystate = {}

local ctrlhold = false
local input = false
-- graphics
local naicon = love.image.newImageData("graphics/natoms/naicon.png")
local kaicon = love.image.newImageData("graphics/icon.png")
local mbg = love.graphics.newImage("graphics/natoms/m_bgcustom.png")
local mnalogo = love.graphics.newImage("graphics/natoms/m_nalogo.png")
local mplayer = love.graphics.newImage("graphics/m_player.png")
local defaultav = love.graphics.newImage("graphics/natoms/defaultav.png")
local mbgnatoms = love.graphics.newImage("graphics/natoms/bgnatoms.png")
local mready = love.graphics.newImage("graphics/natoms/ready.png")
local curimg = mbgnatoms
curimg:setWrap("repeat", "repeat", "repeat")
-- sounds and music
local sndready = love.audio.newSource("sounds/natoms/ready.wav","static")
local sndnotready = love.audio.newSource("sounds/natoms/notready.wav","static")
local music = love.audio.newSource("music/NetworkAtoms.it", "stream")
-- variables
local bgcolor = {1, 1, 1, 1}
local mbglayer = love.graphics.newQuad(0, 0, 640, 480, 128, 128)
local bg_spd = 32
local muspos = 0
local musmuted = false

local chatinput = _NATextBox.newObject(love.graphics.newFont(14),48)

local netmenu = {}  -- for use outside of lobby state


netmenu.ready = false

netmenu.images = {
    [0] = love.graphics.newImage("graphics/natoms/bgnatoms.png"),
    [1] = love.graphics.newImage("graphics/natoms/bgcount1.png"),
    [2] = love.graphics.newImage("graphics/natoms/bgcount2.png"),
    [3] = love.graphics.newImage("graphics/natoms/bgcount3.png"),
    [4] = love.graphics.newImage("graphics/natoms/bgcount4.png"),
    [5] = love.graphics.newImage("graphics/natoms/bgcount5.png")
}

netmenu.playercolor = {
    [1] = {1, 0.2, 0.2, 1}, -- red
    [2] = {0.2, 0.4, 1, 1}, -- blue
    [3] = {0, 1, 0, 1}, -- green
    [4] = {1, 1, 0, 1}, -- yellow
}

function netmenu.setImage(imgindex)
    curimg = netmenu.images[imgindex]
    curimg:setWrap("repeat", "repeat", "repeat")
end

function netmenu.playMusic()
    music:play()
end

function netmenu.stopMusic()
    music:stop()
end

function netmenu.setBgColor(val)
    bgcolor = netmenu.playercolor[val]
end

local function drawRectOutline(x,y,w,h,colbg,colout)
    love.graphics.setColor(colout)
    love.graphics.rectangle("fill",x-2,y-2,w+4,h+4)
    love.graphics.setColor(colbg)
    love.graphics.rectangle("fill",x,y,w,h)
    love.graphics.setColor({1,1,1,1})
end

function lobbystate.init()
    love.window.setTitle("NAtoms")
    love.window.setIcon(naicon)
    curimg = mbgnatoms
    netmenu.ready = false
    input = false
    if not _NAOnline then -- check if the handler is not elready running
        bgcolor = {1, 1, 1, 1}
        net.init()
        net.netmenu = netmenu
    else
        net.ingame = false
        net.waiting = false
        net.disqualified = false
        netmenu.playMusic()
    end
    
    if net.mode == "Server" then
        love.window.setTitle("NAtoms - Server")
    end
    local winh = love.graphics.getHeight()
    local winw = love.graphics.getWidth()
    if winw ~= 640 or winh ~= 480 or _CAOSType == "Web" then
        return 640, 480
    end
end

function lobbystate.update(dt)
    -- scrolling layer stuff
    local offx, offy = mbglayer:getViewport()
    if offx <= -128 then
        offx = 0
    end
    if offy <= -128 then
        offy = 0
    end
    mbglayer:setViewport(offx - dt * bg_spd, offy - dt * bg_spd, 640, 480)

    -- music stuff
    muspos = music:tell("seconds")
    
    if #net.players == 1 then
        if muspos > 9.56 then music:seek(0) end
    elseif #net.players == 2 then
        if muspos > 19.12 then music:seek(9.56) end
    elseif #net.players == 3 then
        if muspos > 28.68 then music:seek(19.12) end
    else
        if muspos > 38.14 then music:seek(28.56) end
    end

    -- server/client logic
    if net.mode == "Server" then
        if net.enethost then
            net.ServerThinker(dt)
        end
    end

    net.ClientThinker(dt)
end

function lobbystate.draw()

    love.graphics.setColor(bgcolor)
    love.graphics.draw(mbg)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(curimg, mbglayer) -- draw scrolling layer
    love.graphics.draw(mnalogo, 300, 0, 0, 0.75, 0.75)
    love.graphics.printf("Players", _CAFont24, 4, 0 ,256,"left")
    if net.connected then
        for i=0,3 do
            if net.players[i+1] then    -- draw open bar with player data (colored player icon, ready status, nick and avatar)
                player = net.players[i+1]
                plyrid = player[1]

                drawRectOutline(0,(i*64)+32,256,64,{0.2,0.2,0.2,1},{0.5,0.5,0.5,1})
                love.graphics.setColor(netmenu.playercolor[plyrid])
                love.graphics.draw(mplayer,0,(i*64)+32)
                love.graphics.setColor({1,1,1,1})

                if player then
                    love.graphics.printf(tostring(player[2]), _CAFont16, 52, (i * 64)+56,128,"center")
                    if player[3] then   -- if player ready
                        love.graphics.draw(mready,0,(i*64)+32)
                    end
                end

                if plyrid == net.yourindex then     -- draw your local avatar
                    love.graphics.draw(net.youravatar,128+64,(i*64)+32)
                else
                    if net.avatars[plyrid] then     -- draw player avatar
                        love.graphics.draw(net.avatars[plyrid][1],128+64,(i*64)+32)
                    else                            -- draw default avatar
                        love.graphics.draw(defaultav,128+64,(i*64)+32)
                    end
                end
                
            else    -- draw closed bar with gray player icon
                drawRectOutline(0,(i*64)+32,64,64,{0.2,0.2,0.2,1},{0.5,0.5,0.5,1})
                love.graphics.draw(mplayer,0,(i*64)+32)
            end
            
        end

        -- Draw Chatbox
        love.graphics.printf("Chat", _CAFont24, 280, 96 ,128,"left")
        drawRectOutline(280,128,336,256,{0,0,0,0.5},{0.5,0.5,0.5,0.5})              -- chat box
        if input then
            drawRectOutline(280,128+256,256+80,20,{0,0,0,0.5},{1,1,1,0.5})       -- chat input (enabled)
            chatinput:draw(282,128+258,input)
        else
            drawRectOutline(280,128+256,256+80,20,{0,0,0,0.5},{0.5,0.5,0.5,0.5})       -- chat input (disabled)
            chatinput:draw(282,128+258,input)
        end
        love.graphics.setColor({1,1,1,1})
        -- chatbox can display 18 lines (14 font)
        for i=0, 17 do
            local str = nil
            if net.chatlog[#net.chatlog-i] then
                str = net.chatlog[#net.chatlog-i]
            end
            if str then
                love.graphics.printf(str,282,(384-18)-(i*14),336+999,"left")
            end
        end

        if _CAIsMobile then
            local wx,wy = _CAState.getWindowSize()
            love.graphics.print("Touch your player box to switch your ready state", 10, wy - 20)
        else
            love.graphics.print("Click your player box or press enter to switch your ready state", 10, love.graphics.getHeight() - 20)
        end
    end
end

function lobbystate.keypressed(key)
    if key == "return" then -- press enter to toggle if ready
        if input then
            if chatinput.input ~= "" then
                net.clientpeer:send(gmpacket.encode("MESSAGE",{chatinput.input}))
                chatinput:clear()
            end
        else
            netmenu.ready = not netmenu.ready
            net.clientpeer:send(gmpacket.encode("READY", {netmenu.ready}))
        end
    end

    if key == "backspace" then
        if input then chatinput:eraselast() end
    end

    if key == "lctrl" then ctrlhold = true end

    if key == "m" then
        if not input then
        musmuted = not musmuted
            if musmuted then
                music:setVolume(0)
                _CAState.printmsg("Music muted",3)
            else
                music:setVolume(1.0)
                _CAState.printmsg("Music un-muted",3)
            end
        end
    end

    if key == "escape" then
        _CAState.printmsg("Disconnecting...", 3)
        if net.mode == "Server" then
            net.stopServer()
        end
        if net.mode == "Client" then
            net.clientpeer:disconnect_now()
            _NAOnline = false
        end
        netmenu.stopMusic()
        love.window.setTitle("KleleAtoms 1.3 (NAtoms)")
        love.window.setIcon(kaicon)
        _CAState.change("menu")
    end
end

function lobbystate.keyreleased(key)
    if key == "lctrl" then ctrlhold = false end
end

function lobbystate.mousepressed(x, y, button)
    if _CAIsMobile then
        netmenu.ready = not netmenu.ready
        net.clientpeer:send(gmpacket.encode("READY", {netmenu.ready}))
    end
end

function lobbystate.textinput(t)
    chatinput:write(t)
end

function lobbystate.mousereleased(x, y, button)
    if x >= 0 and x < 256 and y >= 32+((net.yourindex-1)*64) and y < 96+((net.yourindex-1)*64) then
        netmenu.ready = not netmenu.ready
        net.clientpeer:send(gmpacket.encode("READY", {netmenu.ready}))
    end

    if x >= 280 and x < 280+256+80 and y >= 384 and y < 384+20 then
        input = true
        love.keyboard.setTextInput(input)
    else
        input = false
        love.keyboard.setTextInput(input)
    end
end

function lobbystate.quit()
    net.clientpeer:disconnect_now()
    if (net.mode == "Server") then
        if net.enethost ~= nil then
            net.stopServer()
        end
    end
end

return lobbystate
