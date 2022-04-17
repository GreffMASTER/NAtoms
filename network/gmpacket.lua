local gmpacket = {}

gmpacket.version = "1"

-- The new packet system should be automatic
-- Each element is separated by a specified separator variable "gmpacket.sep" (default is "\n")
-- Example: "PACKETNAME\nOBJECTCOUNT\nTYPE\nVAR\nTYPE\nVAR\n...\nEND"
-- Specific example: "PLAYER\n3\n1\n127.0.0.1\n0\nEND"
-- Types: NUM - integer or float, STRING - string, BOOL - boolean

gmpacket.sep = "\n"

local dataTypes = {
    NUM = function(a)
        return tonumber(a)
    end,
    STRING = function(a)
        return a
    end,
    BOOL = function(a)
        return (a ~= "0")
    end,
    END = function(a)
        return nil
    end
}

local typesToString = {
    number = function()
        return "NUM"
    end,
    string = function()
        return "STRING"
    end,
    boolean = function()
        return "BOOL"
    end
}

local function boolToBit(bool)
    if(bool==true) then
        return 1
    else
        return 0
    end
end


-- Encoding stuff


function gmpacket.encode(packetName,data)
    data = data or nil -- if data is empty, make an empty packet
    local packet = ""

    if(data~=nil) then
        if(type(data) == "table") then
            packet = packetName..gmpacket.sep..#data..gmpacket.sep
        else
            return nil
        end
    end
    for i,v in ipairs(data) do
        if(type(v) == "table") then
            return nil
        end
        if(type(v) == "boolean") then
            packet = packet..typesToString[type(v)]()..gmpacket.sep..boolToBit(v)..gmpacket.sep
        else
            packet = packet..typesToString[type(v)]()..gmpacket.sep..tostring(v)..gmpacket.sep
        end
    end
    packet = packet.."END"
    return packet
end


-- Decoding stuff (works not)


local function setType(type,data)
    return dataTypes[type](data)
end

function gmpacket.decode(str)

    if(str==nil) then
        return nil
    end

    if not string.find(str,gmpacket.sep) then
        return nil
    end

    local data = string.explode(str,gmpacket.sep)
    local packetdata = {
        name = data[1],
        data = {}
    }
    local objectcount = tonumber(data[2])
    
    table.remove(data,1);table.remove(data,1) -- remove packet name and count to get raw packet data

    local i=1
    while i<=objectcount*2 do
        table.insert(packetdata["data"],setType(data[i],data[i+1]))
        i=i+2
    end

    return packetdata
end


-- other stuff


function table.dump(tab)
    if type(tab) == 'table' then
       local s = '{ '
       for k,v in pairs(tab) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. table.dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(tab)
    end
 end

function string.explode(str, div)
    assert(type(str) == "string" and type(div) == "string", "invalid arguments")
    local o = {}
    while true do
        local pos1,pos2 = str:find(div)
        if not pos1 then
            o[#o+1] = str
            break
        end
        o[#o+1],str = str:sub(1,pos1-1),str:sub(pos2+1)
    end
    return o
end

return gmpacket