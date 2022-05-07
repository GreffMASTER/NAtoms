local networkmenustate = {}

local debug = false
local debughold = false
-- graphics
local naicon = love.image.newImageData("graphics/natoms/naicon.png")
local mbg = love.graphics.newImage("graphics/natoms/m_bgcustom.png")
local mnalogo = love.graphics.newImage("graphics/natoms/m_nalogo.png")
local mplayer = love.graphics.newImage("graphics/m_player.png")
local defaultav = love.graphics.newImage("graphics/natoms/defaultav.png")
local mbgnatoms = love.graphics.newImage("graphics/natoms/bgnatoms.png")
local mready = love.graphics.newImage("graphics/natoms/ready.png")
local curimg = mbgnatoms
curimg:setWrap("repeat", "repeat", "repeat")
-- variables
local bgcolor = {1, 1, 1, 1}
local mbglayer = love.graphics.newQuad(0, 0, 640, 480, 128, 128)
local bg_spd = 32
local ready = false

local netmenu = {}  -- for use outside of lobby state

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

function networkmenustate.init()
    love.window.setTitle("NAtoms")
    love.window.setIcon(naicon)
    curimg = mbgnatoms
    ready = false
    if not _NAOnline then -- check if the handler is not elready running
        net.init()
        net.netmenu = netmenu
    else
        net.ingame = false
        net.waiting = false
        net.disqualified = false
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

function networkmenustate.update(dt)
    -- scrolling layer stuff
    local offx, offy = mbglayer:getViewport()
    if offx <= -128 then
        offx = 0
    end
    if offy <= -128 then
        offy = 0
    end
    mbglayer:setViewport(offx - dt * bg_spd, offy - dt * bg_spd, 640, 480)

    -- server/client logic
    if net.mode == "Server" then
        if net.enethost then
            net.ServerThinker(dt)
        end
    end
    net.ClientThinker(dt)
end

function networkmenustate.draw()

    love.graphics.setColor(bgcolor)
    love.graphics.draw(mbg)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(curimg, mbglayer) -- draw scrolling layer
    love.graphics.draw(mnalogo, 300, 0, 0, 0.75, 0.75)

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

        if debug then
            drawRectOutline(280,128,256+80,256,{0,0,0,1},{0.5,0.5,0.5,1}) -- chat box
            drawRectOutline(280,128+256,256,32,{0,0,0,1},{0.5,0.5,0.5,1}) -- chat input (mockup, replace with textbox)
            drawRectOutline(280+256,128+256,80,32,{0.25,0.25,0.25,1},{0.5,0.5,0.5,1}) -- send button (mockup, replace with textbox)
            love.graphics.setColor({1,1,1,1})
            love.graphics.printf("Send",280+256,128+256+8,80,"center")
        end

        if _CAIsMobile then
            local wx,wy = _CAState.getWindowSize()
            love.graphics.print("Touch the screen to switch your ready state", 10, wy - 20)
        else
            love.graphics.print("Press enter to switch your ready state", 10, love.graphics.getHeight() - 20)
        end
    end
end

function networkmenustate.keypressed(key)
    if (key == "return") then -- press enter to toggle if ready
        ready = not ready
        if (ready == true) then
            net.clientpeer:send(gmpacket.encode("IMREADY", {}))
        else
            net.clientpeer:send(gmpacket.encode("IMNOTREADY", {}))
        end
    end

    if key == "lctrl" then debughold = true end

    if key == "d" then
        if debughold then debug = not debug end
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
        love.window.setTitle("KleleAtoms 1.3 (NAtoms)")
        _CAState.change("menu")
    end
end

function networkmenustate.keyreleased(key)
    if key == "lctrl" then debughold = false end
end

function networkmenustate.mousepressed(x, y, button)
    if _CAIsMobile then
        ready = not ready
        if (ready == true) then
            net.clientpeer:send(gmpacket.encode("IMREADY", {}))
        else
            net.clientpeer:send(gmpacket.encode("IMNOTREADY", {}))
        end
    end
end

function networkmenustate.mousereleased(x, y, button)
end

function networkmenustate.quit()
    net.clientpeer:disconnect_now()
    if (net.mode == "Server") then
        if net.enethost ~= nil then
            net.stopServer()
        end
    end
end

return networkmenustate
