local packet = {}

function packet.stringDecode(str)
    local pckt = {}
    arr = string.explode(str,"|")
	if(arr[1]=="PLYRS") then
        local playerdata = {}
        for i=1,(#arr-2)/3 do
            table.insert(playerdata,{})
            for j=1,3 do
                table.insert(playerdata[i],arr[(i-1)*3+j+2])
            end
        end
        pckt = {arr[1],tonumber(arr[2]),playerdata}
	elseif(arr[1]=="READY") then
	    pckt = {arr[1],arr[2],arr[3]} -- packet_type, ip, ready
	elseif(arr[1]=="CONN") then
	    pckt = {arr[1],arr[2]} -- packet_type, ip
	elseif(arr[1]=="DISCONN") then
	    pckt = {arr[1],arr[2]} -- packet_type, ip
    elseif(arr[1]=="COUNTING") then
        pckt = {arr[1],arr[2]} -- packet_type, counter
	elseif(arr[1]=="START") then
        local player_types = {}
        pckt = {arr[1],tonumber(arr[2]),tonumber(arr[3]),tonumber(arr[4])} -- packet_type, x, y, player_types(bitwise)
    elseif(arr[1]=="STOP") then
        pckt = {arr[1]} -- packet_type
	elseif(arr[1]=="INGAME") then
        pckt = {arr[1]} -- packet_type
    end
    return pckt
end

function packet.playerListToString(plyrs)
    out = "PLYRS|"
    out = out..tostring(table.getn(plyrs)).."|"
    for i,p in ipairs(plyrs) do
        if(p~=nil) then
            out = out..p[1].."|"..p[2].."|"..tostring(p[3]).."|"
        end
    end
    out = out.."END"
    return out
end

function packet.playerListToConfig(plyrs)
    out = "START|"
    out = out..tostring(_CAGridW).."|"
    out = out..tostring(_CAGridH).."|"
    local calc = 0
    for i=1,#plyrs do
        calc = calc + 2^(tonumber(plyrs[i][1])-1)
        print(calc)
    end
    out = out..tostring(calc).."|END"
    return out
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

return packet