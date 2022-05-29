local menuonline = {}

local selTB = nil --Selected textbox

local curavatar = nil

local isBackSpace = false

local isDragAndDrop = false --Is the player in the avatar drag and drop menu

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

local tbpos = { --Textbox positions and sizes
    {startx+8,starty+80,wwidth-16,24},
    {startx+8,starty+130,wwidth-16,24},
    {startx+8,starty+192,wwidth-115,24},
}

local sndclick = nil

local function hostfunc()
    net.mode = "Server"
    menuonline.saveData()
    _NAHostIP = "localhost"
    _NAServerIP = textboxes[1].input
    _NAPort = textboxes[2].input
    _NAPlayerNick = textboxes[3].input
    _CAState.change("lobby")
end

local function joinfunc()
    if textboxes[1].input ~= "" then
        net.mode = "Client"
        menuonline.saveData()
        _NAHostIP = nil
        _NAServerIP = textboxes[1].input
        _NAPort = textboxes[2].input
        _NAPlayerNick = textboxes[3].input
        _CAState.change("lobby")
    else
        _CAState.printmsg("Server IP must not be empty to join!",4)
    end
end

local function returnfunc()
    menuonline.isEnabled = false
    menuonline.saveData()
end

local function avatarfunc()
    menuonline.saveData()
    isDragAndDrop = true
end

--"text",x,y,width,height,function
local mobuttons = { --Buttons for online menu
    {"Host",startx+15,starty+260,80,60,hostfunc},
    {"Join",startx+110,starty+260,80,60,joinfunc},
    {"Return",startx+205,starty+260,80,60,returnfunc},
    {"",startx+210,starty+170,70,70,avatarfunc}
}

local buttonpressed = nil

local function drawRectOutline(x,y,w,h,colbg,colout)
    love.graphics.setColor(colout)
    love.graphics.rectangle("fill",x-2,y-2,w+4,h+4)
    love.graphics.setColor(colbg)
    love.graphics.rectangle("fill",x,y,w,h)
end

local function deselectTextbox()
    local tnum = math.floor(tonumber(textboxes[2].input) or 5047)
    tnum = math.min(math.max(tnum, 1025), 49150)
    textboxes[2].input = tostring(tnum)
    selTB = nil
    love.keyboard.setTextInput(false)
end

menuonline.isEnabled = false

function menuonline.saveData()
    deselectTextbox()
    local str = ""
    for k,v in ipairs(textboxes) do
        str = str..v.input.."\n"
    end
    love.filesystem.write("natoms.txt",str)
end

function menuonline.init(scl)
    sndclick = scl
    deselectTextbox()
    isBackSpace = false
    textboxes[1].input = _NAServerIP or ""
    textboxes[2].input = _NAPort or "5047"
    textboxes[3].input = _NAPlayerNick or "Player"
    if love.filesystem.getInfo("avatar.png") then
        curavatar = love.graphics.newImage("avatar.png")
        if curavatar:getWidth() ~= 64 or curavatar:getHeight() ~= 64 then
            curavatar = nil
        end
    end
    if not curavatar then
        curavatar = love.graphics.newImage("graphics/natoms/defaultav.png")
    end
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
    if isDragAndDrop then
        love.graphics.setColor(0,0,0,1)
        local pstr = "Drag and drop a new avatar here.\n\nSupported formats: PNG, JPG, BMP\n\nRecommended size: 64x64\n\nClick anywhere to cancel."
        love.graphics.printf(pstr,_CAFont16,textx,starty+96,textw,"center")
        return
    end
    love.graphics.setColor(0,0,0,1)
    love.graphics.printf("Online Setup",_CAFont32,textx,starty+4,textw,"center")
    love.graphics.printf("Server IP (for joining)",_CAFont16,textx,starty+58,textw,"center")
    if selTB == 1 then
        drawRectOutline(tbpos[1][1],tbpos[1][2],tbpos[1][3],tbpos[1][4],{0.7,0.7,0.7,1},{0,0,0,1})
    else
        drawRectOutline(tbpos[1][1],tbpos[1][2],tbpos[1][3],tbpos[1][4],{1,1,1,1},{0,0,0,1})
    end
    love.graphics.setColor(0,0,0,1)
    textboxes[1]:draw(tbpos[1][1]+2,tbpos[1][2]+2,(selTB==1))
    love.graphics.printf("UDP Port (default: 5047)",_CAFont16,textx,starty+108,textw,"center")
    if selTB == 2 then
        drawRectOutline(tbpos[2][1],tbpos[2][2],tbpos[2][3],tbpos[2][4],{0.7,0.7,0.7,1},{0,0,0,1})
    else
        drawRectOutline(tbpos[2][1],tbpos[2][2],tbpos[2][3],tbpos[2][4],{1,1,1,1},{0,0,0,1})
    end
    love.graphics.setColor(0,0,0,1)
    textboxes[2]:draw(tbpos[2][1]+2,tbpos[2][2]+2,(selTB==2))
    love.graphics.printf("User name",_CAFont16,textx,starty+170,tbpos[3][3],"center")
    if selTB == 3 then
        drawRectOutline(tbpos[3][1],tbpos[3][2],tbpos[3][3],tbpos[3][4],{0.7,0.7,0.7,1},{0,0,0,1})
    else
        drawRectOutline(tbpos[3][1],tbpos[3][2],tbpos[3][3],tbpos[3][4],{1,1,1,1},{0,0,0,1})
    end
    love.graphics.setColor(0,0,0,1)
    textboxes[3]:draw(tbpos[3][1]+2,tbpos[3][2]+2,(selTB==3))
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
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(curavatar,startx+213,starty+173)
end

function menuonline.keypressed(key)
    if selTB then
        if love.keyboard.isDown("lctrl","rctrl") then
            if key == "c" then
                love.system.setClipboardText(textboxes[selTB].input)
            elseif key == "x" then
                love.system.setClipboardText(textboxes[selTB].input)
                textboxes[selTB]:clear()
            elseif key == "v" then
                textboxes[selTB]:setString(string.gsub(love.system.getClipboardText(),"%c+",""):gsub("%s+",""))
            end
        end

        if key == "backspace" then
            textboxes[selTB]:eraselast()
            isBackSpace = true
            bpTimer = -0.15
        end
    end
end

function menuonline.keyreleased(key)
    if key == "backspace" then
        isBackSpace = false
        bpTimer = 0.0
    elseif selTB and key == "return" then
        deselectTextbox()
    end
end

function menuonline.mousepressed(x,y,button)
    if not isDragAndDrop then
        for k,v in ipairs(mobuttons) do
            if x >= v[2] and y >= v[3] and x < v[2]+v[4] and y < v[3]+v[5] then
                buttonpressed = k
                love.audio.play(sndclick)
            end
        end
    end
end

function menuonline.mousereleased(x,y,button)
    if isDragAndDrop then
        isDragAndDrop = false
    elseif buttonpressed then
        mobuttons[buttonpressed][6]()
        buttonpressed = nil
    else
        for k,v in ipairs(tbpos) do
            if x >= v[1] and y >= v[2] and x <= v[1]+v[3] and y <= v[2]+v[4] then
                if k ~= selTB then
                    deselectTextbox()
                    selTB = k
                    if selTB then love.keyboard.setTextInput(true,v[1],v[2],v[3],v[4]) end
                end
                break
            end
        end
    end
end

function menuonline.textinput(t)
    if selTB and textboxes[selTB] and not string.find(t,"%c+") and not string.find(t,"%s+") then
        textboxes[selTB]:write(t)
        if textboxes[selTB]:curWidth() > tbpos[selTB][3]-4 then
            textboxes[selTB]:eraselast()
        end
    end
end

function menuonline.filedropped(file)
    if isDragAndDrop then
        local ext = string.sub(file:getFilename(),-4,-1) --file extension (only 3 letters allowed)
        if ext == ".png" or ext == ".jpg" or ext == ".bmp" then
            file:open("r")
            local data = file:read("data")
            file:close()
            local loadedimg = love.graphics.newImage(data)
            local canvas = love.graphics.newCanvas(64,64)
            canvas:renderTo(function()
                love.graphics.clear()
                love.graphics.setBlendMode("alpha", "premultiplied")
                love.graphics.setColor(1,1,1,1)
                love.graphics.scale(64/loadedimg:getWidth(),64/loadedimg:getHeight())
                love.graphics.draw(loadedimg)
                love.graphics.scale(1,1)
                love.graphics.setBlendMode("alpha", "alphamultiply")
            end)
            local avatardata = canvas:newImageData()
            avatardata:encode("png","avatar.png")
            curavatar = canvas
            _CAState.printmsg("Avatar changed successfully!",4)
        else
            _CAState.printmsg("Invalid file type!",4)
        end
        isDragAndDrop = false
    end
end

--Returns true if the online menu will close, false if not
function menuonline.escPressed()
    if isDragAndDrop then
        isDragAndDrop = false
        return false
    else
        return true
    end
end

return menuonline
