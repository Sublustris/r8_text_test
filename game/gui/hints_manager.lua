local hh 		= require("main.hashes")
local richtext 	= require "richtext.richtext"
local color 	= require "richtext.color"

local M = {}

local hintWords 	= {}
local hintRequested = false
local closeRequested= false

M.hintNode			= nil
M.hintText			= nil
M.hintTextPos 		= nil

M.types = {
	default		= hash("default"),
	building	= hash("building"),
	buildMenu	= hash("buildMenu"),
}

M.hint = {
	type 		= M.types.default,
	text 		= "",
	anchor		= hh.top,
	pos  		= vmath.vector3(),
	worldPos	= vmath.vector3(),
	goHint		= false,
	visible 	= false,
}

--================================================

function M.init()
	M.hintNode			= gui.get_node("hint")
	M.hintText			= gui.get_node("hintText")
	M.hintPos 			= gui.get_position(M.hintNode)
	M.hintTextPos		= gui.get_position(M.hintText)
	M.hint.visible		= false
end

---------------------------------------------------
function M.showRichTextHint(self)	
	gui.set_enabled(M.hintText, false) --скроем простой текст  хинта
	if hintWords[1]  then   --удалим старые ноды ричтекста, чтоб не упереться в лимит
		richtext.remove(hintWords) 
		hintWords ={}
	end
	
	gui.set_pivot(M.hintNode, gui.PIVOT_NW)
	
	M.hintTextPos.x= 10
	M.hintTextPos.y= -10
	
	local textSettings = { 
		parent = M.hintNode,
		position = M.hintTextPos,
		align = richtext.ALIGN_LEFT,
		valign = richtext.VALIGN_MIDDLE,
		width = 300,
		line_spacing = 0.8,
		image_pixel_grid_snap =true,
		combine_words =true
	}		
	local metrics
	hintWords, metrics =  richtext.create(M.hint.text, "tooltip", textSettings)	

	local newSize = vmath.vector3(metrics.width+30, metrics.height+25, 0)
	gui.set_size(M.hintNode, newSize)
			
	gui.set_enabled(M.hintNode, true)
	M.hintPos.x = M.hint.pos.x
	M.hintPos.y = M.hint.pos.y
	gui.set_position(M.hintNode, M.hintPos)
end
--------------------------------------------------
function M.requestHint(type, text, position, anchor)	
	--запрошен показ хинта
	M.hint.text = text
	M.hint.type = type
	M.hint.goHint = false
	M.hint.pos.x =position.x
	M.hint.pos.y =position.y
	M.hint.anchor = anchor
	M.showRichTextHint(self)
end

--------------------------------------------------
return M