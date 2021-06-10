local stts = require("main.settings")
local color = require("utils.color_convert")
local hh = require("main.hashes")
local M ={}

M.guiIsOnScreen		= false
M.nodes 			= {}  --хэндлы всех нод интерфейса для быстрого обращения
M.scriptRoot		= nil --нода в которую рисуются все элементики скрипта
M.scriptElements 	= {}  --для хранения всех показываемых в данный момент элементов скрипта
M.codeChips 		= {}  --структура для хранения полной информации о нодах кода
M.chipsDeltaY		= 60  --промежуток между нодами на панели скрипта (между центрами нод)	

M.cursorPos			= vmath.vector3(0, 0, 0.7)
M.curNode			= nil --это выбранная нода (та, что тащит игрок) также применяется как флаг того, что нода в руках (когда не nil)
M.curNodeStruct		= nil

M.arrows			={} --стрелочки между элементами в джампах

M.curNodeMoving		= false 
M.curNodePos		= vmath.vector3(0, 0, 0.5)  --экранная позиция ноды
M.prevCursorPos 	= vmath.vector3(0, 0, 0.5)	--для расчётов твининга

M.commandbuttonWasPressed =false
M.clickedButtonPos = vmath.vector3(0, 0, 0.5)

M.repairMenuOpened = false
M.betterTexts		={}
M.worstTexts		={}
M.yammer 			={}
M.curDialog			={}

M.colorsTable 		= {  -- для хранения цветовой дифференциации нод
	go_left = vmath.vector4(0.5, 0.5, 0.4, 1),
	go_right = vmath.vector4(0.5, 0.5, 0.4, 1),
	go_up = vmath.vector4(0.5, 0.5, 0.4, 1),
	pick_from_point = vmath.vector4(0.5, 0.5, 0.4, 1),
	go_to_point = vmath.vector4(0.5, 0.5, 0.7, 1),
	
	drop_to_point = vmath.vector4(0.8, 0.5, 0.5, 1),
	combine = vmath.vector4(0.2, 0.8, 0.2, 1),
	pick = vmath.vector4(0.7, 0.7, 0.5, 1),
	drop = vmath.vector4(0.7, 0.7, 0.5, 1),
	
	jump = vmath.vector4(0.8, 0.5, 0.0, 1),
	if_fail =vmath.vector4(0.7, 0.7, 0.5, 1),
	jumpTarget = vmath.vector4(0.8, 0.5, 0.0, 1),
}


M.btnNamesTable = {
	go_left = "step left",
	go_right= "step right",
	go_up ="step up",
	go_down = "step down",
	
	go_to_point = "go to", 
	pick_from_point = "pick from",
	drop_to_point = "drop to",
	stop = "stop",
	combine = "mix",
	pick = "pick from left",
	drop = "drop to right",
	jump = "jump",
	if_fail = "if fail",
	jumpTarget = "",
	if_failTarget ="",
}

-------------------------------------------
--инициализация 
function M.initCodePanel(rootNode)
	M.guiPosition = gui.get_screen_position(rootNode)
	print(M.guiPosition)
end

-------------------------------------------
--получает позицию после которой нужно воткнуть новый элемент
--и создает новый элемент
function M.addCodeChip(name, stepNum, pos, parentHandle, numLabel, argHandle, arg, chipLabel, argLabel )
	local newElement 		= {}	
	newElement.handle 		= parentHandle	--ссылка на ноду
	newElement.numLabel 	= numLabel      --ссылка на текстовую ноду с номером строки (чтоб менять по нужде)
	newElement.argHandle 	= argHandle		--ссылка на ноду с кнопкой аргумента или nil
	newElement.num 			= stepNum  		--номер шага (порядковый номер в стеке)
	newElement.name 		= name			--имя 
	newElement.chipLabel 	= chipLabel		--надпись на кнопке, хэндл
	newElement.argLabel		= argLabel		--напись на кнопке аргумента, хэндл
	newElement.pairID 		= nil
	newElement.weight		= 0.1

	if arg then 
		newElement.arg = vmath.vector3(arg.x, arg.y, arg.z) -- аргумент в формате  vector3 , или nil
		newElement.pairID = arg.z
	end

	--[[
	if (stepNum % 2 == 0) then --сделаем легкую черезполосицу, чтоб лучше читалась панель с кодом
		newElement.bgColor =  vmath.vector4(0,0,0, 0.05)
	else			
		newElement.bgColor =  vmath.vector4(0,0,0, 0.10)
	end
	--]]
	
	newElement.bgColor =  vmath.vector4(0,0,0,0)
	newElement.pos = vmath.vector3(pos.x, pos.y, pos.z) --позиция ноды для всяких твинов и перетаскиваний

	local hType
	if string.sub(name,1, 10) == "jumpTarget" then
		hType =  hash("jumpTarget")	
	elseif string.sub(name,1, 4) == "jump" then
		hType =  hash("jump")	
	elseif 	name ==  "go_to_point" or name =="pick_from_point" or name == "drop_to_point" then
		hType =  hh.pointed
	elseif string.sub(name,1, 13) == "if_failTarget" then
		hType =  hash("if_failTarget")	
	elseif string.sub(name,1, 7) == "if_fail" then
		hType =  hash("if_fail")	
	else
		hType = hash("normal")
	end	
	newElement.type = hType		--тип:  normal ,jump,  jumpTarget , pointed в виде хэша для увеличения скорости обработки
	
	M.codeChips[parentHandle] = newElement  --ключом в табличке будет нода, чтоб проще искать по клику
end


-------------------------------------------
function M.deleteCodeChip(codeChip)
	--проверяем пару
	local pairID
	if codeChip.arg then
		if  codeChip.arg.z ~= 0 then 
			pairID = codeChip.arg.z
		end
	end	
		
	if pairID then --если это пара команд,типа джампа то удалим обе
		for i = #settings.curMob.commands, 1, -1 do
			if settings.curMob.commands[i].arg then
				if settings.curMob.commands[i].arg.z== pairID then
					table.remove(settings.curMob.commands, i)
				end
			end
		end
		--[[
		if pairNum > codeChip.num then
			table.remove(settings.curMob.commands, pairNum)
			table.remove(settings.curMob.commands, codeChip.num)
		else
			table.remove(settings.curMob.commands, codeChip.num)
			table.remove(settings.curMob.commands, pairNum)
		end
		--]]
		
		--и стрелочку
		for k, v in pairs(M.arrows) do
			if k == pairID then
				gui.delete_node(v)
				v= nil
			end
		end
		msg.post("/gui_obj#gui", hash("setSpacerPos"), {indx = codeChip.num - 2})
		
	else --иначе удалим только одну
		table.remove(settings.curMob.commands, codeChip.num)
		msg.post("/gui_obj#gui", hash("setSpacerPos"), {indx = codeChip.num - 1})
	end
	
	msg.post("/gui_obj#gui", hash("loadMobCommands"), {commands = settings.curMob.commands, paused = settings.curMob.stopped})
	--msg.post("/go#script", hash("removeCommand"), {command_num = codeChip.num} )
	
end

local jumpColorDelta =0
-------------------------------------------
function M.pickColor(cName)
	local color = M.colorsTable[cName]
	--if color == nil then color =vmath.vector4(0.5, 0.5, 0.7, 1) end
	--[[
	if cName == "jump" or cName == "jumpTarget" then
		jumpColorDelta = jumpColorDelta + 0.02
		color.y = color.y + jumpColorDelta
	end
	--]]
	
	if color == nil then 
		color = M.colorsTable["default"] 
		print("Для команды ".. cName .. "  цвет не назначен, нужно добавить его в Гуглотабличку на закладку Colors")
	end
	return color
end

--------------------------------------------
function M.getButtonName(commandName)
	if M.btnNamesTable[commandName] then
		return  M.btnNamesTable[commandName]
	else
		print("не найдено название для кнопки с командой "..commandName.. ", нужно добавить его добавить в gm.btnNamesTable")
		return  commandName
	end
end

--------------------------------------------
--[[
function M.findJumpTarget(pairID)
	if pairID == nil then return nil end
	
	local result 
	local hType =  hash("jumpTarget")
	local hType1 =  hash("if_failTarget")
	for k, val in pairs(M.codeChips) do
		if val.pairID == pairID and val.type == hType or val.type == hType1 then
			result =  val
		end
	end
	if result == nil then print("не удалось найти команду с ID ".. pairID) end
	return result
end
--]]
-------------------------------------------
function M.updateJumpPair(jumpTargetStruct)
	local jumpID = jumpTargetStruct.arg.z
	for key, chip in pairs(M.codeChips) do
		if chip.arg then
			if chip.arg.z == jumpID then 
				--найдена пара от этого джамп таргета
				if chip.type == hh.jump or chip.type == hh.if_fail then
					gui.set_text(chip.chipLabel, chip.name .." to "..jumpTargetStruct.num )
				end				
			end
		end	
	end
end

--------------------------------------------
function M.updateArrows()
	print("arrowsUpdate")
	local deltaX = 0
	for k, chip in pairs(M.codeChips) do	
		if chip.type == hh.jumpTarget   or  chip.type == hh.if_failTarget then
			M.setArrowSize(chip.arg.z, deltaX)
			deltaX = deltaX + 5
		end
	end
end
-------------------------------------------
function M.setArrowSize(jumpID, deltaX)	
	local size = vmath.vector3(62+deltaX,0,0)
	local yJump =0
	local yJumpTarget =0	
	local jumpArrowNode = M.arrows[jumpID]
	
	for k, chip in pairs(M.codeChips) do		
		if chip.arg then
			if chip.arg.z == jumpID  then
				if chip.type == hh.jump or chip.type == hh.if_fail then
					yJump = chip.pos.y
				elseif 	chip.type == hh.jumpTarget or chip.type == hh.if_failTarget then
					yJumpTarget = chip.pos.y
				end
			end
		end
	end	
	
	if jumpArrowNode then 
		local pos = gui.get_position(jumpArrowNode)
		if yJump < yJumpTarget then			
			pos.y	= yJump-15
			size.y	= yJumpTarget+32 - yJump	
		else
			pos.y	= yJumpTarget-15
			size.y	= yJump+32 - yJumpTarget	
		end
		gui.set_size(jumpArrowNode , size)
		gui.set_position(jumpArrowNode, pos)
	end
	
end

--------------------------------------------
function M.updateMobScriptFromGuiState(curMobCommands)
	--pprint(curMobCommands)
	for k, chip in pairs(M.codeChips) do		
		curMobCommands[chip.num].name = chip.name
		curMobCommands[chip.num].weight = chip.weight		
		if chip.arg then 
			--
			if curMobCommands[chip.num].arg then
				curMobCommands[chip.num].arg.x = chip.arg.x
				curMobCommands[chip.num].arg.y = chip.arg.y
				curMobCommands[chip.num].arg.z = chip.arg.z
			else
				curMobCommands[chip.num].arg = vmath.vector3(chip.arg.x, chip.arg.y, chip.arg.z)
			end
			--
		else
			curMobCommands[chip.num].arg = nil
		end		
	end	
	--pprint(curMobCommands)
end

--------------------------------------------
function M.getTextForDialog() 
	local t1,t2,t3
	M.curDialog = {}
	t1 = M.yammer[math.random(1, #M.yammer)].phrase	
	M.curDialog.t1 = t1
	

	if math.random() > 0.5 then
		t2 = M.betterTexts[math.random(1, #M.betterTexts)].name
		t3 = M.worstTexts [math.random(1, #M.worstTexts)].name
		M.curDialog.worst  = 2
		M.curDialog.t2 = t2
		M.curDialog.t3 = t3
	else
		t2 = M.worstTexts [math.random(1, #M.worstTexts)].name
		t3 = M.betterTexts[math.random(1, #M.betterTexts)].name		
		M.curDialog.worst  = 1  --номер плохого ответа
		M.curDialog.t2 = t2
		M.curDialog.t3 = t3
	end
	
	return t1,t2,t3
end

-------------------------------------------
function M.deleteScriptElement(pos)
end

-------------------------------------------
--очистка интерфейса перед перерисовкой скрипта или при снятии выделения с моба
--чистится только визуальная часть! Сам скрипт у моба остается без изменений.
function M.clearScript()
end

-------------------------------------------
--загрузка скрипта
function M.loadScript(mob)
end

-------------------------------------------
return M