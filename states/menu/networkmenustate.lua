local networkmenustate = {}

local naicon = love.image.newImageData("graphics/natoms/naicon.png")
local mbg = love.graphics.newImage("graphics/natoms/m_bgcustom.png")
local mnalogo = love.graphics.newImage("graphics/natoms/m_nalogo.png")
local bgcolor = {1, 1, 1, 1}

local mbgnatoms = love.graphics.newImage("graphics/natoms/bgnatoms.png")
local curimg = mbgnatoms
curimg:setWrap("repeat", "repeat", "repeat")

local netmenu = {}

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

local mbglayer = love.graphics.newQuad(0, 0, 640, 480, 128, 128)
local bg_spd = 32

local ready = false

function networkmenustate.init()
    love.window.setTitle("NAtoms")
    love.window.setIcon(naicon)
    curimg = mbgnatoms
    if not _NAOnline then -- check if the handler is not elready running
        net.init()
        net.netmenu = netmenu
    else
        ready = false
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
        net.ServerThinker(dt)
    end
    net.ClientThinker(dt)
end

function networkmenustate.draw()
    love.graphics.setColor(bgcolor)
    love.graphics.draw(mbg)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(curimg, mbglayer) -- draw scrolling layer
    love.graphics.draw(mnalogo, 320, -20, 0, 0.75, 0.75)

    for i, p in ipairs(net.players) do
        if p ~= nil then
            local youtext = ""
            local readytext = "not ready."
            if p[1] == net.yourindex then
                youtext = " <- You"
            end
            if p[3] then
                readytext = "ready."
            end
            love.graphics.print("Player " .. tostring(p[1]) .. ": " .. p[2] .. " is " .. readytext .. youtext, 10, i * 20)
        end
    end

    if _CAIsMobile then
        local wx,wy = _CAState.getWindowSize()
        love.graphics.print("Touch the screen to switch your ready state", 10, wy - 20)
    else
        love.graphics.print("Press enter to switch your ready state", 10, love.graphics.getHeight() - 20)
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
