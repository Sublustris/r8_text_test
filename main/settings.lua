-- Put functions in this file to use them in several other scripts.
-- To get access to the functions, you need to put:
-- require "my_directory.my_file"
-- in any script using the functions.

local M ={}
	M.tileSize		=128
	M.screen_width  =1920
	M.screen_height =1080
	M.maxCamX		=0
	M.maxCamY		=0  --максимальное положение камеры 	
	M.game_width  	=0
	M.game_height 	=0
	M.shake 		=0

	M.moneyCount	=9000
	
	M.initialParams ={}
	M.elementsTable ={}
	M.knownElements ={}  --для контроля уже изученных элементов
	M.scriptOnPause =false
	M.scriptRunning =false
	M.map = {}
	M.avalCommands = { -- формат команды {имя = флаг наличия аргумента}
		go_left 		=false,
		go_right 		=false,
		go_up 			=false,
		go_down			=false,
		go_to_point		=true, 
		stop			=false,
		combine			=false,
		pick			=false,
		drop			=false,
		pick_from_point =true,
		drop_to_point	=true
	}  
	M.groundPos =vmath.vector3(0,0,0)
	M.curMob 	=nil
	
	M.scrollSpeed 		=vmath.vector3(0,0,0)
	M.scrollDelta		=20
	M.arrowButtonPressed=false
	M.maxClickTime 		=0.30  --  socket.gettime()  возвращает время в секундах
	M.wikiOnScreen		=false
	
	
	
	--M.staticZoomX   =1280/640
	--M.staticZoomY   =720/360	
	-- движок автоматически масштабирует координаты клика, независимо от размеров окна и они привязаны к размерам игрового проекта 
	-- поэтому нужно хранить только скейл относительно  проецируемый размер/размер проекта	
return M