local menuonline = {}

local selTB = nil --Selected textbox

local isBackSpace = false

local bpTimer = 0.0 --Backspace timer

local textboxes = {
    _NATextBox.newObject(_CAFont16,24), --IP address (client mode only)
    _NATextBox.newObject(_CAFont16,5), --Port (default 5047)
    _NATextBox.newObject(_CAFont16,16) --Player nick
}

local startx = 170
local starty = 70
local wwidth = 300
local wheight = 340

local tbpos = { --Textbox positions
    {startx+4,starty+80,startx+wwidth-16,starty+105},
    {startx+4,starty+130,startx+wwidth-16,starty+155},
    {startx+4,starty+180,startx+wwidth-16,starty+205},
}

local sndclick = nil

local function hostfunc()
    net.mode = "Server"
    _NAHostIP = "localhost"
    _NAServerIP = nil
    _NAPort = textboxes[2].input
    _NAPlayerNick = textboxes[3].input
    menuonline.saveData()
    _CAState.change("netmenu")
end

local function joinfunc()
    if textboxes[1].input ~= "" then
        net.mode = "Client"
        _NAHostIP = nil
        _NAServerIP = textboxes[1].input
        _NAPort = textboxes[2].input
        _NAPlayerNick = textboxes[3].input
        menuonline.saveData()
        _CAState.change("netmenu")
    else
        _CAState.printmsg("Server IP must not be empty to join!",4)
    end
end

local function returnfunc()
    menuonline.isEnabled = false
    menuonline.saveData()
end

--"text",x,y,width,height,function
local mobuttons = { --Buttons for online menu
    {"Host",startx+15,starty+260,80,60,hostfunc},
    {"Join",startx+110,starty+260,80,60,joinfunc},
    {"Return",startx+205,starty+260,80,60,returnfunc},
}

local buttonpressed = nil

local function drawRectOutline(x,y,w,h,colbg,colout)
    love.graphics.setColor(colout)
    love.graphics.rectangle("fill",x-2,y-2,w+4,h+4)
    love.graphics.setColor(colbg)
    love.graphics.rectangle("fill",x,y,w,h)
end

menuonline.isEnabled = false

function menuonline.saveData()
    local str = ""
    for k,v in ipairs(textboxes) do
        str = str..v.input.."\n"
    end
    love.filesystem.write("natoms.txt",str)
end

function menuonline.init(scl)
    sndclick = scl
    selTB = nil
    isBackSpace = false
    textboxes[1].input = _NAServerIP or ""
    textboxes[2].input = _NAPort or "5047"
    textboxes[3].input = _NAPlayerNick or "Player"
end

function menuonline.update(dt)
    if isBackSpace then
        bpTimer = bpTimer + dt
        if bpTimer >= 0.05 and selTB and textboxes[selTB] then
            bpTimer = 0.0
            textboxes[selTB]:eraselast()
        end
    end
end

function menuonline.draw()
    local textx = startx + 8
    local textw = wwidth-16 --Text width
    love.graphics.setColor(0,0,0,0.5)
    love.graphics.rectangle("fill",0,0,_CAState.getWindowSize())
    drawRectOutline(startx,starty,wwidth,wheight,{0.5,0.5,0.5,1},{1,1,1,1})
    love.graphics.setColor(0,0,0,1)
    love.graphics.printf("Online Setup",_CAFont32,textx,starty+4,textw,"center")
    love.graphics.printf("Server IP (for joining)",_CAFont16,textx,starty+58,textw,"center")
    if selTB == 1 then
        drawRectOutline(textx,starty+80,textw,24,{0.7,0.7,0.7,1},{0,0,0,1})
    else
        drawRectOutline(textx,starty+80,textw,24,{1,1,1,1},{0,0,0,1})
    end
    love.graphics.setColor(0,0,0,1)
    textboxes[1]:draw(textx+2,starty+82,(selTB==1))
    love.graphics.printf("UDP Port (default: 5047)",_CAFont16,textx,starty+108,textw,"center")
    if selTB == 2 then
        drawRectOutline(textx,starty+130,textw,24,{0.7,0.7,0.7,1},{0,0,0,1})
    else
        drawRectOutline(textx,starty+130,textw,24,{1,1,1,1},{0,0,0,1})
    end
    love.graphics.setColor(0,0,0,1)
    textboxes[2]:draw(textx+2,starty+132,(selTB==2))
    love.graphics.printf("User name",_CAFont16,textx,starty+158,textw,"center")
    if selTB == 3 then
        drawRectOutline(textx,starty+180,textw,24,{0.7,0.7,0.7,1},{0,0,0,1})
    else
        drawRectOutline(textx,starty+180,textw,24,{1,1,1,1},{0,0,0,1})
    end
    love.graphics.setColor(0,0,0,1)
    textboxes[3]:draw(textx+2,starty+182,(selTB==3))
    for k,v in ipairs(mobuttons) do
        mx,my = _CAState.getMousePos()
        if buttonpressed == k or (not buttonpressed and mx >= v[2] and my >= v[3] and mx < v[2]+v[4] and my < v[3]+v[5]) then
            drawRectOutline(v[2],v[3],v[4],v[5],{0.5,0.5,0.5,1},{1,1,1,1})
        else
            drawRectOutline(v[2],v[3],v[4],v[5],{0.7,0.7,0.7,1},{1,1,1,1})
        end
        love.graphics.setColor(0,0,0,1)
        love.graphics.printf(v[1],_CAFont16,v[2],v[3]+(v[5]/3),v[4],"center")
    end
end

function menuonline.keypressed(key)
    if key == "backspace" then
        textboxes[selTB]:eraselast()
        isBackSpace = true
        bpTimer = -0.15
    end
end

function menuonline.keyreleased(key)
    if key == "backspace" then
        isBackSpace = false
        bpTimer = 0.0
    end
end

function menuonline.mousepressed(x,y,button)
    for k,v in ipairs(mobuttons) do
        if x >= v[2] and y >= v[3] and x < v[2]+v[4] and y < v[3]+v[5] then
            buttonpressed = k
            love.audio.play(sndclick)
        end
    end
end

function menuonline.mousereleased(x,y,button)
    if buttonpressed then
        mobuttons[buttonpressed][6]()
        buttonpressed = nil
    else
        local newSelect = false
        for k,v in ipairs(tbpos) do
            if x >= v[1] and x <= v[3] and y >= v[2] and y <= v[4] then
                selTB = k
                newSelect = true
                break
            end
        end
        if not newSelect then selTB = nil end
    end
end

function menuonline.textinput(t)
    if selTB and textboxes[selTB] and not string.find(t,"%c") then
        textboxes[selTB]:write(t)
        if selTB == 2 then
            local tnum = math.floor(tonumber(textboxes[selTB].input) or 5047)
            tnum = math.min(math.max(tnum, 1025), 49150)
            textboxes[selTB].input = tostring(tnum)
        end
    end
end

return menuonline
