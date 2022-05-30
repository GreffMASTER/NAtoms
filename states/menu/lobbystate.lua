local lobbystate = {}

local buttonpressed = nil --Button pressed number (or nil if none)
local buttonrepeat = nil --If the button is a repeating action, it's not nil
local buttontimer = 0.0 --Button repeat timer
local isbackspace = false --Is backspace held?
local bptimer = 0.0 --Backspace repeat timer
local input = false
-- graphics
local naicon = love.image.newImageData("graphics/natoms/naicon.png")
local mbg = love.graphics.newImage("graphics/natoms/m_bgcustom.png")
local mnalogo = love.graphics.newImage("graphics/natoms/m_nalogo.png")
local mplayer = love.graphics.newImage("graphics/m_player.png")
local defaultav = love.graphics.newImage("graphics/natoms/defaultav.png")
local mbgnatoms = love.graphics.newImage("graphics/natoms/bgnatoms.png")
local mready = love.graphics.newImage("graphics/natoms/ready.png")
local mmuson = love.graphics.newImage("graphics/natoms/namuson.png")
local mmusoff = love.graphics.newImage("graphics/natoms/namusoff.png")
local mop = love.graphics.newImage("graphics/natoms/op.png")
local mgh = love.graphics.newImage("graphics/m_gh.png")
local mgw = love.graphics.newImage("graphics/m_gw.png")
local curimg = mbgnatoms
curimg:setWrap("repeat", "repeat", "repeat")
local chatcontents = love.graphics.newCanvas(336,256)
-- sounds and music
local sndready = love.audio.newSource("sounds/natoms/ready.wav","static")
local sndnotready = love.audio.newSource("sounds/natoms/notready.wav","static")
local music = love.audio.newSource("music/NetworkAtoms.it", "stream")
local sndclick = love.audio.newSource("sounds/click.wav","static")
-- variables
local bgcolor = {1, 1, 1, 1}
local mbglayer = love.graphics.newQuad(0, 0, 640, 480, 128, 128)
local bg_spd = 32
local muspos = 0
local musmuted = false
local chatfont = love.graphics.newFont(12)

local chatinput = _NATextBox.newObject(love.graphics.newFont(14),48)

local netmenu = {}  -- for use outside of lobby state

local function moveStep(varname,min,max) --Add 1 to value, set to minimal value if too high
    _G[varname] = _G[varname] + 1
    if min > max then min, max = max, min end
    if _G[varname] > max then
        _G[varname] = min
    end
end

local function moveStepBack(varname,min,max) --Remove 1 from value, set to max value if too low
    _G[varname] = _G[varname] - 1
    if min > max then min, max = max, min end
    if _G[varname] < min then
        _G[varname] = max
    end
end

local function readyFunc()
    netmenu.ready = not netmenu.ready
    net.clientpeer:send(gmpacket.encode("READY", {netmenu.ready}))
    if netmenu.ready then love.audio.play(sndready) else love.audio.play(sndnotready) end
    return nil
end

local function readyColorFunc()
    if netmenu.ready then return "READY",{1,1,1,1} else return "READY",{0,0,0,1} end
end

local function gwFunc(button)
    if button == 2 then
        moveStepBack("_CAGridW",7,30)
    else
        moveStep("_CAGridW",7,30)
    end
    return button
end

local function ghFunc(button)
    if button == 2 then
        moveStepBack("_CAGridH",4,20)
    else
        moveStep("_CAGridH",4,20)
    end
    return button
end

local function quitFunc(button)
    net.disconnect()
    return button
end

local function quitText()
    return "QUIT",{1,1,1,1}
end

--icon/nil, hostOnly, x, y, width, height, func(mouse_button) -> repeatButton[, colorfunc() -> value,color]
-- OR
--icon/nil, hostOnly, x, y, width, height, func(mouse_button) -> repeatButton, global_value_name
local buttons = {
    {nil,false,10,300,128,64,readyFunc,readyColorFunc},
    {nil,false,10,380,128,64,quitFunc,quitText},
    {mgw,true,148,300,122,64,gwFunc,"_CAGridW"},
    {mgh,true,148,380,122,64,ghFunc,"_CAGridH"},
}

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

local function findCommand(inputstr)
    local result = inputstr
    for k,v in pairs(net.commandlist) do
        local found = v:find(inputstr,1,true)
        if found == 1 then
            result = v
        end
    end
    return result
end

local function chatDraw()
    love.graphics.clear()
    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.setColor(1,1,1,1)
    local linenum = 1
    local msgnum = #net.chatlog
    local drawy = 252
    local ttext = love.graphics.newText(chatfont)
    repeat
        if not net.chatlog[msgnum] then break end
        local slines = 1
        ttext:setf(net.chatlog[msgnum],336,"left")
        slines = math.ceil(ttext:getHeight()/chatfont:getHeight())
        drawy = drawy - slines*14
        love.graphics.draw(ttext,0,drawy)
        linenum = linenum + slines
        msgnum = msgnum - 1
    until(linenum > 18)
    love.graphics.setBlendMode("alpha", "alphamultiply")
end

function lobbystate.init()
    isbackspace = false
    bptimer = 0.0
    buttonpressed = nil
    buttonrepeat = nil
    buttontimer = 0.0
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
    -- timers
    if isbackspace then bptimer = bptimer + dt end
    if buttonrepeat then buttontimer = buttontimer + dt end

    -- button repeat stuff
    if buttonrepeat and buttontimer >= 0.1 then
        buttontimer = 0.0
        buttons[buttonpressed][7](buttonrepeat)
        love.audio.play(sndclick)
    end

    -- backspace repeat stuff
    if input and isbackspace and bptimer >= 0.05 then
        bptimer = 0.0
        chatinput:eraselast()
    end

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

    -- chatbox stuff
    chatcontents:renderTo(chatDraw)
    
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
    love.graphics.printf("v."..net.version, 570, 76 ,70,"left")
    if net.connected then
        love.graphics.printf("Players", _CAFont24, 4, 0 ,256,"left")
        for i=0,3 do
            if net.players[i+1] then    -- draw open bar with player data (colored player icon, ready status, nick and avatar)
                player = net.players[i+1]
                plyrid = player[1]

                drawRectOutline(0,(i*64)+32,256,64,{0,0,0,0.5},{0.5,0.5,0.5,0.5})
                love.graphics.setColor(netmenu.playercolor[plyrid])
                love.graphics.draw(mplayer,0,(i*64)+32)
                love.graphics.setColor({1,1,1,1})
                if plyrid == 1 then love.graphics.draw(mop,19,(i*64)+18) end
                if player then
                    love.graphics.printf(player[2], _CAFont16, 60, (i * 64)+56,128,"center")
                    if player[3] then   -- if player ready
                        love.graphics.draw(mready,19,(i*64)+64)
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
                drawRectOutline(0,(i*64)+32,64,64,{0,0,0,0.5},{0.5,0.5,0.5,0.5})
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

        love.graphics.draw(chatcontents,280,128)

        --Draw buttons
        for k,v in ipairs(buttons) do
            if not v[2] or (v[2] and net.mode == "Server") then
                mx, my = _CAState.getMousePos()
                if buttonpressed == k or (mx >= v[3] and mx < v[3]+v[5] and my >= v[4] and my <= v[4]+v[6]) then
                    drawRectOutline(v[3],v[4],v[5],v[6],{0,0,0,0.5},{0.3,0.3,0.3,0.5})
                else
                    drawRectOutline(v[3],v[4],v[5],v[6],{0,0,0,0.5},{0.5,0.5,0.5,0.5})
                end
                local ncolor = {1,1,1,1}
                local value = ""
                if type(v[8]) == "function" then
                    local tempval
                    tempval, ncolor = v[8]() --colorfunc()
                    if tempval ~= nil then value = tostring(tempval) end
                else
                    if _G[v[8]] ~= nil then value = tostring(_G[v[8]]) end
                end
                local y = ((v[6] - _CAFont24:getHeight()) / 2) + v[4]
                if v[1] and v[1]:typeOf("Texture") then
                    love.graphics.draw(v[1],v[3],v[4])
                    local iw = v[1]:getWidth()
                    love.graphics.setColor(ncolor)
                    love.graphics.printf(value,_CAFont24,v[3]+iw,y,v[5]-iw,"center")
                else
                    love.graphics.setColor(ncolor)
                    love.graphics.printf(value,_CAFont24,v[3],y,v[5],"center")
                end
            end
        end
        love.graphics.setColor(1,1,1,1)
        if not musmuted then
            love.graphics.draw(mmuson,594,434)
        else
            love.graphics.draw(mmusoff,594,434)
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
            if netmenu.ready then love.audio.play(sndready) else love.audio.play(sndnotready) end
        end
    end

    if input and key == "backspace" then
        chatinput:eraselast()
        isbackspace = true
        bptimer = -0.15
    end

    if key == "t" then
        if not input then
            input = true
            love.keyboard.setTextInput(input)
        end
    end
    
    if key == "/" then
        if not input then
            input = true
            love.keyboard.setTextInput(input)
            chatinput:setString("/")
        end
    end

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
        if input then
            input = false
            chatinput:clear()
            love.keyboard.setTextInput(input)
        else
            net.disconnect()
        end
    end

    if key == "tab" then
        if input and chatinput.input:len() > 1 and chatinput.input:sub(1,1) == "/" then
            chatinput:setString("/"..findCommand(chatinput.input:sub(2,-1)))
        end
    end
end

function lobbystate.keyreleased(key)
    if key == "backspace" then
        isbackspace = false
        bptimer = 0.0
    end
end

function lobbystate.mousepressed(x, y, button)
    for k,v in ipairs(buttons) do
        if not v[2] or (v[2] and net.mode == "Server") then
            if x >= v[3] and x < v[3]+v[5] and y >= v[4] and y < v[4]+v[6] then
                buttonpressed = k
                buttonrepeat = v[7](button)
                if buttonrepeat then buttontimer = -0.1 end
                love.audio.play(sndclick)
            end
        end
    end

    if x >= 594 and y >= 434 and x <= 594+44 and y <= 434+44 then
        musmuted = not musmuted
        love.audio.play(sndclick)
        if musmuted then
            music:setVolume(0)
            _CAState.printmsg("Music muted",3)
        else
            music:setVolume(1.0)
            _CAState.printmsg("Music un-muted",3)
        end
    end
end

function lobbystate.textinput(t)
    if input and chatinput:curWidth() <= 332 then
        chatinput:write(t)
    end
end

function lobbystate.mousereleased(x, y, button)
    if x >= 280 and x < 280+256+80 and y >= 384 and y < 384+20 then
        input = true
        love.keyboard.setTextInput(input)
    else
        input = false
        chatinput:clear()
        love.keyboard.setTextInput(input)
    end

    if buttonpressed then
        buttontimer = 0.0
        buttonrepeat = nil
        buttonpressed = nil
    end
end

function lobbystate.focus(focus)
    if not focus then
        input = false
        chatinput:clear()
        love.keyboard.setTextInput(input)
    end
end

function lobbystate.stop()
    netmenu.stopMusic()
end

function lobbystate.quit()
    net.disconnect()
end

return lobbystate
