--Settings
  --Currency Settings:
local currencyname = "Diamond Piece"
local exchangerate = 1000 -- exchangerate * 1 point = 1 diamond 
  --Name Settings:
local namelength = 25 --Length of Names
local identicalnames = false --If names of cards can be identical
  --Pin Settings:
local pinlength = 6 --Length of Pins
local hidepin = true --Hide Pin when entering
local pinattempts = 5 --Reset on consecutive failures
  --Exchange Settings:
local maxdeposit = 256 -- Max deposit at a time (MAX 1024)
local maxwithdrawal = 128 -- Max withdrawal at a time (MAX 1024)
  --Optional Settings:
local resetonreturn = true --Reset card name text when returning to page from menu
--=============

local m = peripheral.wrap("top")
local d = peripheral.wrap("back")
rednet.open("right")

m.setTextScale(0.5)

--Simplification Functions
function getEvent(...) --Input = {buttons buttonObject}
	local args = {...}
	local eventdata = {os.pullEvent()}
	local event = eventdata[1]
	
	if event == "monitor_touch" then
		for i,v in ipairs(args[1]) do
			if eventdata[3] > v["xmin"]-1 and eventdata[3] < v["xmax"]+1 and eventdata[4] > v["ymin"]-1 and eventdata[4] < v["ymax"]+1 then
				return v["additionals"][1]
			end
		end
	end
end

local caps = false
local shifts = false
function getKeyEvent(...) --Input = {keyboard_type String, rows rowObject, buttons buttonObject}
	local args = {...}
	local eventdata = {os.pullEvent()}
	local event = eventdata[1]
	if event == "monitor_touch" then
		for i,v in ipairs(args[2]) do
			if eventdata[3] > v["xmin"]-1 and eventdata[3] < v["xmax"]+1 and eventdata[4] > v["ymin"]-1 and eventdata[4] < v["ymax"]+1 then
				if args[1] == "fullboard" and caps and not (v["capskeys"][math.floor((eventdata[3]-v["xmin"])/3)+1] == nil) then
					textwriter("fullboard",v["capskeys"][math.floor((eventdata[3]-v["xmin"])/3)+1])
					break
				else
					textwriter(args[1],v["keys"][math.floor((eventdata[3]-v["xmin"])/3)+1])
					break
				end
			end
		end
		for i,v in ipairs(args[3]) do
			if eventdata[3] > v["xmin"]-1 and eventdata[3] < v["xmax"]+1 and eventdata[4] > v["ymin"]-1 and eventdata[4] < v["ymax"]+1 then
				if v["additionals"][1] then
					textwriter(args[1], v["additionals"][2])
					return
				else
					return v["additionals"][2]
				end
			end
		end
	end
end

function advancedwriter(text, row, foreground, background)
	local emptyrow = "                                                         "
	local left = ""
	local right = ""
	local foregroundC = ""
	local backgroundC = ""
	
	if (57-#text)%2==0 then
		left = emptyrow:sub(1, (57-#text)/2)
		right = left
	else
		left = emptyrow:sub(1, ((57-#text)/2)-0.5)
		right = emptyrow:sub(1, ((57-#text)/2)+0.5)
	end
	
	for iText=1,#text,1 do
		foregroundC = foregroundC .. foreground 
		backgroundC = backgroundC .. background
	end
	
	m.setCursorPos(1,row)
	m.write(left)
	m.setCursorPos(#left+1,row)
	m.blit(text, foregroundC, backgroundC)
	m.setCursorPos(#left+#text+1,row)
	m.write(right)
end

local typedtext = ""
local hiddentext = ""
local emptytext = "_________________________"
local emptypintext = "-------------------------"

function textwriter(keytype, key)
	if keytype == "numpad" then
		if not (#typedtext == pinlength) then
			typedtext = typedtext .. key
			hiddentext = hiddentext .. "*"
			if hidepin then
				advancedwriter(hiddentext..emptypintext:sub(1,pinlength-#hiddentext), 6, "4", "f")
			else
				advancedwriter(typedtext..emptypintext:sub(1,pinlength-#typedtext), 6, "4", "f")
			end
			return
		end
	elseif keytype == "fullboard" then
		if key == "backspace" then
			typedtext = typedtext:sub(1,#typedtext-1)
			hiddentext = hiddentext:sub(1,#hiddentext-1)
		elseif key == "space" then
			if not (#typedtext == 0) then
				typedtext = typedtext .. " "
				hiddentext = hiddentext .. "*"
			end
		elseif not (#typedtext == #emptytext) then
			if caps then
				if shifts then
					advancedwriter("  [q][w][e][r][t][y][u][i][o][p][-]   ", 16, "4", "f")
					advancedwriter("[Cap][a][s][d][f][g][h][j][k][l][_]   ", 17, "4", "f")
					advancedwriter("[Shft][z][x][c][v][b][n][m][,][.][~]  ", 18, "4", "f")
					caps = false
					shifts = false
				end
			end
			typedtext = typedtext .. key
			hiddentext = hiddentext .. "*"
		end
		advancedwriter(typedtext..emptytext:sub(1,#emptytext-#typedtext), 6, "4", "f")
	end
end

function buttonObject(xmin, xmax, ymin, ymax, additionals)
	local button = {}
	button["xmin"] = xmin 
	button["xmax"] = xmax
	button["ymin"] = ymin
	button["ymax"] = ymax
	button["additionals"] = additionals
	return button
end

function rowObject(xmin, xmax, ymin, ymax, keyArray, capsArray)
	local row = {}
	row["xmin"] = xmin
	row["xmax"] = xmax
	row["ymin"] = ymin
	row["ymax"] = ymax
	row["keys"] = keyArray
	row["capskeys"] = capsArray
	return row
end

function formattedNumber(msg)
	if msg%1==0 then
		msg = msg .. ""
		local fmsg = ""
		if #msg > 3 then
			for i = #msg, 1,-1 do -- and not ((#msg-i)==0)
				if ((#msg-i)+1)%3==0 and not (i==1) then
					fmsg = "," .. msg:sub(i,i) .. fmsg
				else
					fmsg = msg:sub(i,i) .. fmsg
				end
			end
		else
			fmsg = msg
		end
		return fmsg
	else
		local fmsg = (msg%1)..""
		if #fmsg > 3 then -- .2345
			fmsg = fmsg:sub(2,4)
		else	
			fmsg = fmsg:sub(2)
		end
		return formattedNumber(math.floor(msg))..fmsg
	end
end

--UI Functions
function CardUI(hasCard, bankState)
	m.clear()
	m.setCursorPos(22,9)
	m.blit("              ", "ffffffffffffff", "eeeeeeeeeeeeff")
	m.setCursorPos(22,10)
	m.blit("              ", "ffffffffffffff", "ee7777777ff7ef")
	m.setCursorPos(22,11)
	m.blit("              ", "ffffffffffffff", "ee7777777ff77e")
	m.setCursorPos(22,12)
	m.blit("              ", "ffffffffffffff", "eeeeeeeeeeeeee")
	m.setCursorPos(22,13)
	m.blit("              ", "ffffffffffffff", "e000000000000e")
	m.setCursorPos(22,14)
	m.blit("              ", "ffffffffffffff", "e088888888880e")
	m.setCursorPos(22,15)
	m.blit("              ", "ffffffffffffff", "e000000000000e")
	m.setCursorPos(22,16)
	m.blit("              ", "ffffffffffffff", "e088888888880e")
	m.setCursorPos(22,17)
	m.blit("              ", "ffffffffffffff", "e000000000000e")
	m.setCursorPos(22,18)
	m.blit("              ", "ffffffffffffff", "e000000000000e")
	m.setCursorPos(22,19)
	m.blit("              ", "ffffffffffffff", "eeeeeeeeeeeeee")
	
	if hasCard then --Returning Card
		if bankState == "getcard" or bankState == "lostcard" then
			advancedwriter("Creating card...", 6, "4", "f")
		else
			advancedwriter("Returning card...", 6, "4", "f")
		end
		turtle.turnRight()
		turtle.turnRight()
		turtle.suck()
		turtle.turnRight()
		turtle.turnRight()
		turtle.drop()
		return true
	else --Taking Card
		advancedwriter("Please insert your card into the chest,", 5, "4", "f")
		advancedwriter("then press the screen to continue.", 6, "4", "f")
		advancedwriter(" [Cancel] ", 22, "4", "f")
		
		local buttons = {}
		buttons[1] = buttonObject(25,32,22,22,{"MainMenu"})
		buttons[2] = buttonObject(1,57,1,24,{"TestCard"})
		
		local fetchEvent = nil
		while true do
			fetchEvent = getEvent(buttons)
			if fetchEvent == "MainMenu" then
				return false
			else
				turtle.suck()
				if not (turtle.getItemCount(1) == 0) then
					if turtle.getItemDetail(1).name == "computercraft:disk_expanded" then
						advancedwriter("", 5, "4", "f")
						advancedwriter("Processing...", 6, "4", "f")
						advancedwriter(" ", 22, "4", "f")
					
						turtle.turnRight()
						turtle.turnRight()
						turtle.drop()
						turtle.turnRight()
						turtle.turnRight()
						
						rednet.broadcast("verify card "..d.getDiskID(), "CentralBank1")
						local id1, response, ptcl1 = rednet.receive("CentralBank1", 3)
						if response then
							return true
						else
							turtle.turnRight()
							turtle.turnRight()
							turtle.suck()
							turtle.turnRight()
							turtle.turnRight()
							turtle.drop()
							
							advancedwriter("Card not accepted!!", 5, "e", "f")
							advancedwriter("", 6, "4", "f")
							sleep(2)
							advancedwriter("Please insert your card into the chest,", 5, "4", "f")
							advancedwriter("then press the screen to continue.", 6, "4", "f")
							advancedwriter(" [Cancel] ", 22, "4", "f")
						end
					else
						turtle.drop()
					end
				end
			end
		end
	end
end

function TextUI(state)
	m.clear()
	if state == "getcard" then
		advancedwriter("Type in the Name for your card", 3, "5", "f")
	else
		advancedwriter("Type in the Name of your card", 3, "5", "f")
	end
	
	advancedwriter(typedtext..emptytext:sub(1,#emptytext-#typedtext), 6, "4", "f")
	
	advancedwriter("  [1][2][3][4][5][6][7][8][9][0][ <- ]", 15, "4", "f")
	advancedwriter("  [q][w][e][r][t][y][u][i][o][p][-]   ", 16, "4", "f")
	advancedwriter("[Cap][a][s][d][f][g][h][j][k][l][_]   ", 17, "4", "f")
	advancedwriter("[Shft][z][x][c][v][b][n][m][,][.][~]  ", 18, "4", "f")
	--advancedwriter("         [    Space    ]              ", 19, "4", "f")
	
	advancedwriter("[Return]                                   [Enter]", 23, "4", "r")

	local buttonrows = {}
	buttonrows[1] = rowObject(12,41,15,15,{"1","2","3","4","5","6","7","8","9","0"}, {})
	buttonrows[2] = rowObject(12,44,16,16,{"q","w","e","r","t","y","u","i","o","p","-"}, {"Q","W","E","R","T","Y","U","I","O","P"})
	buttonrows[3] = rowObject(15,44,17,17,{"a","s","d","f","g","h","j","k","l","_"}, {"A","S","D","F","G","H","J","K","L"})
	buttonrows[4] = rowObject(16,45,18,18,{"z","x","c","v","b","n","m",",",".","~"}, {"Z","X","C","V","B","N","M"})

	local buttons = {}
	buttons[1] = buttonObject(42,47,15,15, {true,"backspace"})
	buttons[2] = buttonObject(10,14,17,17, {false,"caps"})
	buttons[3] = buttonObject(10,15,18,18, {false,"shift"})
	--buttons[4] = buttonObject(19,33,19,19, {true,"space"})
	buttons[4] = buttonObject(4,11,23,23, {false,"return"})
	buttons[5] = buttonObject(47,53,23,23, {false,"enter"})
	
	caps = false
	shifts = false
	
	local fetchEvent = nil
	while not (fetchEvent == "enter" and not (typedtext == "")) or not (fetchEvent == "return") do
		fetchEvent = getKeyEvent("fullboard", buttonrows, buttons)
		if fetchEvent == "caps" then
			if caps then 
				advancedwriter("  [q][w][e][r][t][y][u][i][o][p][-]   ", 16, "4", "f")
				advancedwriter("[Cap][a][s][d][f][g][h][j][k][l][_]   ", 17, "4", "f")
				advancedwriter("[Shft][z][x][c][v][b][n][m][,][.][~]  ", 18, "4", "f")
				caps = false
				shifts = false
			else
				advancedwriter("  [Q][W][E][R][T][Y][U][I][O][P][-]   ", 16, "4", "f")
				advancedwriter("[Cap][A][S][D][F][G][H][J][K][L][_]   ", 17, "4", "f")
				advancedwriter("[Shft][Z][X][C][V][B][N][M][,][.][~]  ", 18, "4", "f")
				caps = true
				shifts = false
			end
		elseif fetchEvent == "shift" then
			if caps then 
				advancedwriter("  [q][w][e][r][t][y][u][i][o][p][-]   ", 16, "4", "f")
				advancedwriter("[Cap][a][s][d][f][g][h][j][k][l][_]   ", 17, "4", "f")
				advancedwriter("[Shft][z][x][c][v][b][n][m][,][.][~]  ", 18, "4", "f")
				caps = false
				shifts = false
			else
				advancedwriter("  [Q][W][E][R][T][Y][U][I][O][P][-]   ", 16, "4", "f")
				advancedwriter("[Cap][A][S][D][F][G][H][J][K][L][_]   ", 17, "4", "f")
				advancedwriter("[Shft][Z][X][C][V][B][N][M][,][.][~]  ", 18, "4", "f")
				caps = true
				shifts = true
			end
		elseif fetchEvent == "return" then
			if resetonreturn then
				typedtext = ""
			end
			return false
		elseif fetchEvent == "enter" and not (typedtext == "") then
			if state == "lostcard" then
				rednet.broadcast("verify name "..typedtext.." true", "CentralBank1")
				local id1, response, ptcl1 = rednet.receive("CentralBank1", 3)
				if response then
					return true
				else
					advancedwriter("Invalid Name", 8, "e", "f")
					sleep(2)
					advancedwriter("", 8, "e", "f")
				end
			elseif not identicalnames then
				rednet.broadcast("verify name "..typedtext.." false", "CentralBank1")
				local id1, response, ptcl1 = rednet.receive("CentralBank1", 3)
				if response then
					return true
				else
					advancedwriter("Name already taken", 8, "e", "f")
					sleep(2)
					advancedwriter("", 8, "e", "f")
				end
			else
				return true
			end
		end
	end
end

function PinUI(state, cardid)
	m.clear()
	if state == "create" then
		advancedwriter("  Enter a PIN:  ", 3, "4", "f")
	elseif state == "verify" then
		advancedwriter("  Retype your PIN:  ", 3, "4", "f")
	elseif state == "login" or state == "lostcard" then
		advancedwriter("  Enter your PIN:  ", 3, "4", "f")
	end
	
	advancedwriter(emptypintext:sub(1,pinlength), 6, "4", "f")
	advancedwriter("  [1][2][3]  ", 17, "4", "f")
	advancedwriter("  [4][5][6]  ", 18, "4", "f")
	advancedwriter("  [7][8][9]  ", 19, "4", "f")
	advancedwriter("  [X][0][>]  ", 20, "4", "f")
	
	local buttonrows = {}
	buttonrows[1] = rowObject(25,33,17,17,{"1","2","3"},{})
	buttonrows[2] = rowObject(25,33,18,18,{"4","5","6"},{})
	buttonrows[3] = rowObject(25,33,19,19,{"7","8","9"},{})
	
	local buttons = {}
	buttons[1] = buttonObject(25,27,20,20, {false,"X"})
	buttons[2] = buttonObject(28,30,20,20, {true,"0"})
	buttons[3] = buttonObject(31,33,20,20, {false,">"})
	
	local fetchEvent = nil
	local currentfails = 0
	while true do
		fetchEvent = getKeyEvent("numpad", buttonrows, buttons)
		if fetchEvent == "X" then
			if state == "login" and #typedtext == 0 then
				typedtext = ""
				hiddentext = ""
				return false
			else
				typedtext = ""
				hiddentext = ""
				advancedwriter(emptypintext:sub(1,pinlength), 6, "4", "f")
			end
		elseif fetchEvent == ">" then
			if #typedtext == pinlength then
				if state == "login" or state == "lostcard" then
					if state == "login" then
						rednet.broadcast("verify pin "..d.getDiskID().." "..typedtext, "CentralBank1")
					else
						rednet.broadcast("verify pin "..cardid.." "..typedtext, "CentralBank1")
					end
					local id1, response, ptcl1 = rednet.receive("CentralBank1", 3)
					if response then
						if state == "login" then
							typedtext = ""
						end
						hiddentext = ""
						return true
					else
						advancedwriter("Incorrect PIN", 9, "e", "f")
						sleep(1)
						advancedwriter("", 9, "4", "f")
						advancedwriter(emptypintext:sub(1,pinlength), 6, "4", "f")
						currentfails = currentfails + 1
						if currentfails == pinattempts then
							m.clear()
							advancedwriter("Max PIN attempts exceeded!", 9, "e", "f")
							sleep(3)
							typedtext = ""
							hiddentext = ""
							return false
						else	
							typedtext = ""
							hiddentext = ""
						end
					end
				else
					return typedtext
				end
			end
		end
	end
end

function VerificationUI()
	if not (typedtext == nil) and not (typedtext == "") then
		m.clear()
		advancedwriter("Does this look correct?", 3, "5", "f")
		advancedwriter(typedtext, 6, "4", "f")
		advancedwriter("[No]          [Yes]", 17, "4", "f")
		
		local buttons = {}
		buttons[1] = buttonObject(20, 23, 17, 17, {false})
		buttons[2] = buttonObject(34, 38, 17, 17, {true})
		
		local fetchEvent = nil
		while fetchEvent == nil do
			fetchEvent = getEvent(buttons)
		end
		if fetchEvent then
			return true
		else
			return false
		end	
	end
end

--Main Functions
function Main()
	m.clear()

	advancedwriter("Welcome to the bank, What can I do for you?", 3, "1" , "f")

	advancedwriter("                              ", 7, "4", "b")
	advancedwriter("            Login             ", 8, "4", "b")
	advancedwriter("                              ", 9, "4", "b")

	advancedwriter("                              ", 11, "4", "b")
	advancedwriter("           Get Card           ", 12, "4", "b")
	advancedwriter("                              ", 13, "4", "b")
	
	advancedwriter("                              ", 15, "4", "b")
	advancedwriter("         Recover Card         ", 16, "4", "b")
	advancedwriter("                              ", 17, "4", "b")
	
	local buttons = {}
	buttons[1] = buttonObject(16,42,7,9,{"Login"})
	buttons[2] = buttonObject(16,42,11,13,{"GetCard"})
	buttons[3] = buttonObject(16,42,15,17,{"LostCard"})

	advancedwriter("Select one of the 3 above options, or if you have", 22, "d", "f")
	advancedwriter("a question please ask a representative.", 23, "d", "f")

	local fetchEvent = nil
	while fetchEvent == nil do
		fetchEvent = getEvent(buttons)
	end
	if fetchEvent == "Login" then
		Login()
	elseif fetchEvent == "GetCard" then
		GetCard()
	else
		LostCard()
	end
end

function Login()
	if CardUI(false, "login") then
		if PinUI("login",0) then
			Account()
		else
			CardUI(true, "login")
		end
	end
end

function GetCard()
	local beenBroken = false
	while not VerificationUI() do
		if not TextUI("getcard") then
			beenBroken = true
			break
		end
	end
	if beenBroken then
		return
	end
	local cardName = typedtext
	typedtext = ""
	hiddentext = ""
	
	local pass1 = "test"
	local pass2 = "test2"
	while not (pass1 == pass2) do
		pass1 = PinUI("create",0)
		typedtext = ""
		hiddentext = ""
		pass2 = PinUI("verify",0)
		typedtext = ""
		hiddentext = ""
		if not (pass1 == pass2) then
			advancedwriter("PINs does not match, please retype your PIN", 9, "e", "f")
			sleep(1)
			advancedwriter("", 9, "e", "f")
		end
	end
	
	turtle.select(1)
	turtle.turnRight()
	turtle.suck()
	if turtle.getItemCount(1) == 1 then
		turtle.turnRight()
		turtle.drop()
		turtle.turnRight()
		turtle.turnRight()
		rednet.broadcast("create "..cardName.." "..d.getDiskID().." "..pass1, "CentralBank1")
		local id1, response, ptcl1 = rednet.receive("CentralBank1", 3)
		if response then
			d.setDiskLabel(cardName)
			CardUI(true, "getcard")
		else
			turtle.turnRight()
			turtle.turnRight()
			turtle.suck()
			turtle.turnLeft()
			turtle.drop()
			turtle.turnLeft()
		end
	else
		turtle.drop()
		turtle.turnLeft()
	end
end

function LostCard()
	if TextUI("lostcard") then
		local cardName = typedtext
		typedtext = ""
		hiddentext = ""
		rednet.broadcast("get id "..cardName, "CentralBank1")
		local id1, response, ptcl1 = rednet.receive("CentralBank1", 3)
		if not (response == 0) and PinUI("lostcard",response) then
			local cardPin = typedtext
			typedtext = ""
			hiddentext = ""
			turtle.select(1)
			turtle.turnRight()
			turtle.suck()
			if turtle.getItemCount(1) == 1 then
				turtle.turnRight()
				turtle.drop()
				turtle.turnRight()
				turtle.turnRight()
				rednet.broadcast("update id "..cardName.." "..cardPin.." "..d.getDiskID(), "CentralBank1")
				local id1, response, ptcl1 = rednet.receive("CentralBank1", 3)
				if response then
					d.setDiskLabel(cardName)
					CardUI(true, "lostcard")
				else
					turtle.turnRight()
					turtle.turnRight()
					turtle.suck()
					turtle.turnLeft()
					turtle.drop()
					turtle.turnLeft()
				end
			else
				turtle.drop()
				turtle.turnLeft()
			end
		end
	end
end

function Account()
	rednet.broadcast("get name "..d.getDiskID(), "CentralBank1")
	local id1, cardName, ptcl1 = rednet.receive("CentralBank1", 3)
	if not (cardName == d.getDiskLabel()) then
		d.setDiskLabel(cardName)
	end
	while true do
		m.clear()
		
		advancedwriter("Welcome back, "..d.getDiskLabel(), 3, "1" , "f")

		advancedwriter("                              ", 7, "4", "b")
		advancedwriter("         View Balance         ", 8, "4", "b")
		advancedwriter("                              ", 9, "4", "b")
		
		advancedwriter("                              ", 11, "4", "b")
		advancedwriter("      Deposit / Withdraw      ", 12, "4", "b")
		advancedwriter("                              ", 13, "4", "b")
		
		advancedwriter("                              ", 15, "4", "b")
		advancedwriter("        Update Password       ", 16, "4", "b")
		advancedwriter("                              ", 17, "4", "b")
		
		advancedwriter("                              ", 19, "4", "b")
		advancedwriter("            Logout            ", 20, "4", "b")
		advancedwriter("                              ", 21, "4", "b")
		
		local buttons = {}
		buttons[1] = buttonObject(16,42,7,9,{"Balance"})
		buttons[2] = buttonObject(16,42,11,13,{"Deposit/Withdraw"})
		buttons[3] = buttonObject(16,42,15,17,{"Password"})
		buttons[4] = buttonObject(16,42,19,21,{"Logout"})
		
		local fetchEvent = nil
		while fetchEvent == nil do
			fetchEvent = getEvent(buttons)
		end
		if fetchEvent == "Balance" then
			Balance()
		elseif fetchEvent == "Deposit/Withdraw" then
			DepositWithdraw()
		elseif fetchEvent == "Password" then
			local newpass
			if PinUI("login", 0) then
				newpass = PinUI("create", 0)
				if not (newpass == nil) then
					rednet.broadcast("update pin "..d.getDiskID().." "..newpass, "CentralBank1")
					local id1, isSuccessful, ptcl1 = rednet.receive("CentralBank1", 3)
					typedtext = ""
					hiddentext = ""
				end
			end			
		elseif fetchEvent == "Logout" then
			CardUI(true, "logout")
			return
		end
	end
end

function Balance()
	rednet.broadcast("get balance "..d.getDiskID(), "CentralBank1")
	local id1, balance, ptcl1 = rednet.receive("CentralBank1", 3)

	m.clear()
	advancedwriter("Welcome, "..d.getDiskLabel(), 4, "4", "f")
	advancedwriter("Balance: "..formattedNumber(balance).." "..currencyname, 6, "4", "f")
	
	advancedwriter("     Purchase History     ", 9, "4", "f")
	advancedwriter("--------------------------", 10, "4", "f")
	advancedwriter("  Coming Soon  ", 12, "4", "f")
	
	advancedwriter("                                          [Return]", 23, "4", "r")
	
	while true do 
		if getEvent({buttonObject(46,53,23,23,{"Continue"})}) == "Continue" then
			break
		end
	end
end

function DepositWithdraw()
	rednet.broadcast("get balance "..d.getDiskID(), "CentralBank1")
	local id1, balance, ptcl1 = rednet.receive("CentralBank1", 3)
	
	m.clear()
	advancedwriter("Withdraw/Deposit", 4, "4", "f")
	advancedwriter("Exchange Rate", 6, "4", "f")
	advancedwriter("----------------", 7, "4", "f")
	advancedwriter("1 Diamond = "..formattedNumber(exchangerate).." "..currencyname, 8, "4", "f")
	advancedwriter("Balance: "..formattedNumber(balance).." "..currencyname.." / "..formattedNumber(balance/exchangerate).." Diamonds", 13, "4", "f")
	advancedwriter(" ----------- 0 Diamonds ", 15, "4", "f")
	advancedwriter("[-64][-10][-1]  [+1][+10][+64]", 16, "4", "f")
	advancedwriter("[Exchange]", 20, "4", "f")
	advancedwriter("                                          [Return]", 23, "4", "r")
	
	local buttons = {}
	buttons[1] = buttonObject(14,18,16,16,{"-64"})
	buttons[2] = buttonObject(19,23,16,16,{"-10"})
	buttons[3] = buttonObject(24,27,16,16,{"-1"})
	
	buttons[4] = buttonObject(30,34,16,16,{"+1"})
	buttons[5] = buttonObject(35,39,16,16,{"+10"})
	buttons[6] = buttonObject(40,44,16,16,{"+64"})
	
	buttons[7] = buttonObject(24,33,20,20,{"Exchange"})
	buttons[8] = buttonObject(46,53,23,23,{"Continue"})
	
	local fetchEvent = nil
	local transaction = 0
	while true do
		fetchEvent = getEvent(buttons)
		if fetchEvent == "Exchange" then
			if transaction > 0 then
				local paymentCollected = paymentCollection(transaction)
				if paymentCollected > 0 then
					rednet.broadcast("update balance "..d.getDiskID().." "..paymentCollected*exchangerate, "CentralBank1")
					local id1, success, ptcl1 = rednet.receive("CentralBank1", 3)
					if success then
						balance = balance + paymentCollected*exchangerate
					end
				end
				
			elseif transaction < 0 then
				advancedwriter("Processing...", 20, "4", "f")
				if (transaction*-1)<64 then
					turtle.suckDown(transaction*-1)
				else
					for i=1,math.floor((transaction*-1)/64)+1,1 do
						if i == math.floor((transaction*-1)/64) then
							turtle.suckDown((transaction*-1)%64)
						else
							turtle.suckDown(64)
						end
					end
				end
				local collectedPayout = 0
				local payoutPos = 1
				while true do
					if turtle.getItemCount(payoutPos) == 0 then
						break
					end
					collectedPayout = collectedPayout + turtle.getItemCount(payoutPos)
					turtle.drop()
					payoutPos = payoutPos + 1
					turtle.select(payoutPos)
				end
				turtle.select(1)
				rednet.broadcast("update balance "..d.getDiskID().." "..(collectedPayout*-1)*exchangerate, "CentralBank1")
				local id1, success, ptcl1 = rednet.receive("CentralBank1", 3)
				if success then
					balance = balance - collectedPayout*exchangerate
				end
			end
			transaction = 0
			m.clear()
			advancedwriter("Withdraw/Deposit", 4, "4", "f")
			advancedwriter("Exchange Rate", 6, "4", "f")
			advancedwriter("----------------", 7, "4", "f")
			advancedwriter("1 Diamond = "..formattedNumber(exchangerate).." "..currencyname, 8, "4", "f")
			advancedwriter("Balance: "..formattedNumber(balance).." "..currencyname.." / "..formattedNumber(balance/exchangerate).." Diamonds", 13, "4", "f")
			advancedwriter(" ----------- 0 Diamonds ", 15, "4", "f")
			advancedwriter("[-64][-10][-1]  [+1][+10][+64]", 16, "4", "f")
			advancedwriter("[Exchange]", 20, "4", "f")
			advancedwriter("                                          [Return]", 23, "4", "r")
		elseif fetchEvent == "Continue" then
			break
		elseif not (fetchEvent == nil) then
			local adjustment = fetchEvent:sub(2,#fetchEvent)
			if fetchEvent:sub(1,1) == "+" then
				if transaction+adjustment>maxdeposit then
					transaction = maxdeposit
				else
					transaction = transaction + adjustment
				end
			elseif fetchEvent:sub(1,1) == "-" then
				transaction = transaction - adjustment
				if transaction<((balance/exchangerate)*-1) then
					transaction = (balance/exchangerate)*-1
				end
				if transaction<(maxwithdrawal*-1) then
					transaction = maxwithdrawal*-1
				end
			end
			if transaction == 0 then
				advancedwriter(" ----------- 0 Diamonds ", 15, "4", "f")
			elseif transaction < 0 then
				advancedwriter(" Withdrawing "..formattedNumber(transaction*-1).." Diamonds ", 15, "4", "f")
			else
				advancedwriter(" Depositing "..formattedNumber(transaction).." Diamonds ", 15, "4", "f")
			end
		end	
	end
end

function paymentCollection(transaction)
	m.clear()
	advancedwriter("Awaiting Deposit...", 6, "4", "f")
	advancedwriter("0/"..formattedNumber(transaction).." Diamonds Deposited", 9, "4", "f")
	advancedwriter("Click the screen to Update", 11, "4", "f")
	advancedwriter("[Cancel]", 20, "4", "f")
	
	local buttons = {}
	buttons[1] = buttonObject(25,32,20,20,{"Escape"})
	buttons[2] = buttonObject(1,57,1,24,{"Test"})
	
	local collectedPayment = 0
	local fetchEvent = nil
	while true do
		fetchEvent = getEvent(buttons)
		if fetchEvent == "Escape" then
			if collectedPayment > 0 then
				return collectedPayment
			else
				return 0
			end
		elseif fetchEvent == "Test" then		
			local stackscollected = -1
			local successfulSuck = true
			
			while successfulSuck do
				successfulSuck = turtle.suck()
				stackscollected = stackscollected + 1
			end
			if stackscollected > 0 then
				advancedwriter("Processing...", 20, "4", "f")
				local selectedpos = 1
				local selecteditem
				
				while true do
					selecteditem = turtle.getItemDetail()
					if not (selecteditem == nil) then
						if selecteditem.name == "minecraft:diamond" then
							if transaction == collectedPayment then
								turtle.drop()
							elseif selecteditem.count > transaction - collectedPayment then
								turtle.dropDown(transaction - collectedPayment)
								collectedPayment = transaction
								turtle.drop()
							else
								collectedPayment = collectedPayment + selecteditem.count
								turtle.dropDown()
							end
						else
							turtle.drop()
						end
					else
						break
					end
					selectedpos = selectedpos + 1
					turtle.select(selectedpos)
				end
				turtle.select(1)
				advancedwriter(collectedPayment.."/"..formattedNumber(transaction).." Diamonds Deposited", 9, "4", "f")
				advancedwriter("[Continue]", 20, "4", "f")
				if transaction == collectedPayment then
					return collectedPayment
				end
			end
		end
	end
end

local cyclenum = 0
while true do
	cyclenum = cyclenum + 1
	print(cyclenum)
	Main()
end
