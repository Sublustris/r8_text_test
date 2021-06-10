local M = {}

function  M.fromHex (hex, alpha) 
	local hSign, redColor,greenColor, blueColor = hex:match('(.)(..)(..)(..)')
	redColor, greenColor, blueColor = tonumber(redColor, 16)/255, tonumber(greenColor, 16)/255, tonumber(blueColor, 16)/255
	redColor, greenColor, blueColor = math.floor(redColor*100)/100, math.floor(greenColor*100)/100, math.floor(blueColor*100)/100
	if alpha == nil then
		alpha = 1
	end
	return vmath.vector4(redColor, greenColor, blueColor, alpha)
end

----------------------------------------
function M.fromV4toHex (cv4) 
	local redColor,greenColor,blueColor = string.format("%x", cv4.x * 255),  string.format("%x", cv4.y * 255),  string.format("%x", cv4.z * 255)
	return "#" .. redColor .. greenColor .. blueColor
end

----------------------------------------
function  M.fromRgb (r, g, b)
	local redColor,greenColor,blueColor=r/255, g/255, b/255
	redColor, greenColor, blueColor = math.floor(redColor*100)/100, math.floor(greenColor*100)/100, math.floor(blueColor*100)/100
	return redColor, greenColor, blueColor
end

----------------------------------------
function  M.fromRgba (r, g, b, alpha)
	local redColor,greenColor,blueColor=r/255, g/255, b/255
	redColor, greenColor, blueColor = math.floor(redColor*100)/100, math.floor(greenColor*100)/100, math.floor(blueColor*100)/100
	return redColor, greenColor, blueColor, alpha
end

return M