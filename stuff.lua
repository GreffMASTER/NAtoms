local stuff = {}

function stuff.imgDataToB64(imgdata)
    datastr = imgdata:getString()
    encoded = love.data.encode("string","base64",datastr)
    return encoded
end

function stuff.B64ToData(str,format)
    datastr = love.data.decode("string","base64",str)
    decoded = love.image.newImageData(64, 64, format, datastr)
    return decoded
end

return stuff
