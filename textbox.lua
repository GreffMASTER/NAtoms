local textbox = {}

local function textboxSub(self,i,j)
    utf8.sub(self.input,i,j)
end

local function textboxLength(self)
    return utf8.len(self.input)
end

local function textboxWidth(self)
    return self.font:getWidth(self.prestr..self.input)
end

local function textboxDraw(self,x,y,showcursor)
    if type(x) ~= "number" then error("textboxDraw: x is not a number",2) end
    if type(y) ~= "number" then error("textboxDraw: y is not a number",2) end
    local prevfont = love.graphics.getFont()
    love.graphics.setFont(self.font)
    if showcursor then
        love.graphics.print(self.prestr..self.input.."_",x,y)
    else
        love.graphics.print(self.prestr..self.input,x,y)
    end
    love.graphics.setFont(prevfont)
end

local function textboxWrite(self,str)
    --It is meant to be used with love.textinput() and str is a utf8 string
    assert(str,"textboxWrite: str is nil or false")
    if textboxLength(self) < self.charlimit or self.charlimit == 0 then
        self.input = self.input..str
    end
end

local function textboxSetString(self,str)
    --Unlike textboxWrite, it's meant to be used everywhere but love.textinput()
    assert(str,"textboxWrite: str is nil or false")
    if self.charlimit == 0 then
        self.input = str
    else
        self.input = utf8.sub(str,1,self.charlimit)
    end
end

local function textboxEraseLast(self)
    local byteoffset = utf8.offset(self.input, -1)
    if byteoffset then
        self.input = string.sub(self.input, 1, byteoffset - 1)
    end
end

local function textboxClear(self)
    self.input = ""
end

function textbox.newObject(fontsize,charlimit,prestr)
    --prestr is a string that will be printed before the textbox input string (if it exists)
    --charlimit is character limit (0 is unlimited - NOT RECOMMENDED)
    --if you want not to define charlimit but define prestr, set charlimit to 0 or nil
    --fontsize is required to be a number or a font class
    local newtbox = {}
    if type(fontsize) ~= "number" then
        if type(fontsize) ~= "userdata" then
            error("TextBox NewObject: fontsize is not a number or a font object",2) 
        elseif fontsize:typeOf("Font") then
            newtbox.font = fontsize
        else
            error("TextBox NewObject: fontsize is not a number or a font object",2)
        end
    else
        newtbox.font = love.graphics.newFont(fontsize)
    end
    if type(prestr) == "string" then
        newtbox.prestr = prestr
    else
        newtbox.prestr = ""
    end
    if type(charlimit) == "number" then
        newtbox.charlimit = charlimit
    else
        newtbox.charlimit = 0
    end
    newtbox.draw = textboxDraw
    newtbox.input = ""
    newtbox.write = textboxWrite
    newtbox.clear = textboxClear
    newtbox.eraselast = textboxEraseLast
    newtbox.length = textboxLength
    newtbox.curWidth = textboxWidth
    newtbox.sub = textboxSub
    newtbox.setString = textboxSetString
    return newtbox
end

return textbox
