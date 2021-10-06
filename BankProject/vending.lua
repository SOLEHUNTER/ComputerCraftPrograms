--Settings:
local price = 200
local currency = "Diamond Piece"
local pluralcurrency = "s" --For grammer nerds
local productnum = 63 --Amount of the product the buyer recieves
local product = "baked potato"
local pluralproduct = "es" --For grammer nerds
--Pin Settings:
local pinlength = 6 --Length of Pins
local hidepin = true --Hide Pin when entering
local pinattempts = 5 --Reset on consecutive failures
--==============--

local Fcurrency = currency:sub(1,1):upper()..currency:sub(2,#currency)
local Fproduct = product:sub(1,1):upper()..product:sub(2,#product)

--Startup
d = peripheral.wrap("bottom")
m = peripheral.wrap("back")
rednet.open("right")

m.setTextScale(0.5)
turtle.select(1)

if price <= 1 then
	pluralcurrency = ""
end	
if productnum <= 1 then
	pluralproduct = ""
end

local purchasing = false
local amountpaid = 0

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

function getKeyEvent(...) --Input = {rows rowObject, buttons buttonObject}
	local args = {...}
	local eventdata = {os.pullEvent()}
	local event = eventdata[1]
	if event == "monitor_touch" then
		for i,v in ipairs(args[1]) do
			if eventdata[3] > v["xmin"]-1 and eventdata[3] < v["xmax"]+1 and eventdata[4] > v["ymin"]-1 and eventdata[4] < v["ymax"]+1 then
				textwriter(v["keys"][math.floor((eventdata[3]-v["xmin"])/3)+1])
				break
			end
		end
		for i,v in ipairs(args[2]) do
			if eventdata[3] > v["xmin"]-1 and eventdata[3] < v["xmax"]+1 and eventdata[4] > v["ymin"]-1 and eventdata[4] < v["ymax"]+1 then
				if v["additionals"][1] then
					textwriter(v["additionals"][2])
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
local emptypintext = "-------------------------"

function textwriter(key)
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
end

function centerer(text, length)
	local emptyrow = "                                                         "
	if #text < length then
		if (length-#text)%2==0 then
			text = emptyrow:sub(1,(length-#text)/2)..text..emptyrow:sub(1,(length-#text)/2)
		else
			text = emptyrow:sub(1,math.floor((length-#text)/2))..text..emptyrow:sub(1,math.floor((length-#text)/2)+1)
		end
		return text
	else
		return text
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

function rowObject(xmin, xmax, ymin, ymax, keyArray)
	local row = {}
	row["xmin"] = xmin
	row["xmax"] = xmax
	row["ymin"] = ymin
	row["ymax"] = ymax
	row["keys"] = keyArray
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

function refill(side) -- side: 1 = "left", 2 = "forward", 3 = "right"
	if side == 1 then
		turtle.turnLeft()
		checkrefill()
		turtle.turnRight()
	elseif side == 2 then
		checkrefill()
	elseif side == 3 then
		turtle.turnRight()
		checkrefill()
		turtle.turnLeft()
	end
	if side < 3 then
		refill(side + 1)
	end
end

function checkrefill()
	local has_block, data = turtle.inspect()
	if has_block and data.name == "minecraft:chest" then
		turtle.suck()
		if not (turtle.getItemCount(2) == 0) then
			turtle.select(2)
			turtle.drop(turtle.getItemCount(2))
			turtle.select(1)
		end
	end
end

function Main()
	m.clear()
	advancedwriter(Fproduct..pluralproduct.." for sale!!", 3, "1" , "f")
	
	advancedwriter("=================================================", 6, "1" , "f")
	advancedwriter(productnum .. " " .. Fproduct .. pluralproduct .. " for " .. price .. " " .. Fcurrency .. pluralcurrency .. "!", 8, "1" , "f")
	advancedwriter(productnum*2 .. " " .. Fproduct .. pluralproduct .. " for " .. price*2 .. " " .. Fcurrency .. pluralcurrency .. "!", 10, "1" , "f")
	advancedwriter(productnum*5 .. " " .. Fproduct .. pluralproduct .. " for " .. price*5 .. " " .. Fcurrency .. pluralcurrency .. "!", 12, "1" , "f")
	advancedwriter("=================================================", 14, "1" , "f")
	
	advancedwriter("Click the screen if you would like to purchase", 19, "1" , "f")
	
	local buttons = {}
	buttons[1] = buttonObject(1,57,1,24,{"Continue"})
	
	local fetchEvent = nil
	while fetchEvent == nil do
		fetchEvent = getEvent(buttons)
	end
	
	if fetchEvent == "Continue" then
		if CardUI() then
			if PinUI() then
				while true do
					m.clear()
					rednet.broadcast("get balance "..d.getDiskID(), "CentralBank1")
					local id1, response, ptcl1 = rednet.receive("CentralBank1", 3)
					local userchoice = PurchaseOptions(response)
					if userchoice[1] then 
						print("Choice #"..userchoice[2])
						
						local itemPos = 2
						local selectedChest = 1
						local collectedproduct = 0
						
						turtle.turnLeft()
						turtle.select(2)
						while not(selectedChest == 4) and productnum*userchoice[2]-collectedproduct > 63 do
							if turtle.getItemCount(itemPos) == 0 then
								turtle.suck(64)
							else
								turtle.suck(turtle.getItemSpace(itemPos))
							end
							if turtle.getItemCount(itemPos) == 64 then
								collectedproduct = collectedproduct + 64
								itemPos = itemPos + 1
							else
								selectedChest = selectedChest + 1
								if not(selectedChest == 4) then
									turtle.turnRight()
								end
							end
						end
						while not(selectedChest == 4) and not(collectedproduct == productnum*userchoice[2]) do
							local priorsuck = turtle.getItemCount(itemPos)
							--print((productnum*userchoice[2]).." "..collectedproduct)
							turtle.suck((productnum*userchoice[2])-collectedproduct)
							if not(productnum*userchoice[2] == collectedproduct) then
								collectedproduct = collectedproduct + (turtle.getItemCount(itemPos) - priorsuck)
								selectedChest = selectedChest + 1
								if not(selectedChest == 4) then
									turtle.turnRight()
								end
							else
								collectedproduct = productnum*userchoice[2]
							end
						end
						if not(collectedproduct == productnum*userchoice[2]) and selectedChest == 4 then
							turtle.turnRight()
							turtle.turnRight()
							for i=itemPos,2,-1 do
								turtle.select(i)
								turtle.drop()
							end
							turtle.turnRight()
							turtle.select(1)
							turtle.dropUp()
							
							m.clear()
							advancedwriter("Purchase Unsuccessful", 7, "1" , "f")
							sleep(2)
							advancedwriter("", 7, "1" , "f")
						else
							if selectedChest == 1 then
								turtle.turnRight()
							elseif selectedChest > 2 then
								turtle.turnLeft()
							end
							
							rednet.broadcast("completepurchase 0 "..d.getDiskID().." "..price*userchoice[2], "CentralBank1")
							local id1, response, ptcl1 = rednet.receive("CentralBank1", 3)
							if response then
								print("You spent "..price*userchoice[2])
								for i=itemPos,1,-1 do
									turtle.select(i)
									turtle.dropUp()
								end
								
								m.clear()
								advancedwriter("Purchase Successful", 7, "1" , "f")
								sleep(2)
								advancedwriter("", 7, "1" , "f")
							else
								turtle.turnLeft()
								for i=itemPos,2,-1 do
									turtle.select(i)
									turtle.drop()
								end
								turtle.turnRight()
								turtle.select(1)
								turtle.dropUp()
								
								m.clear()
								advancedwriter("Purchase Unsuccessful", 7, "1" , "f")
								sleep(2)
								advancedwriter("", 7, "1" , "f")
							end
						end
					else
						turtle.suckDown()
						turtle.dropUp()
						break
					end
				end
			end
		end
	end
end

function PurchaseOptions(balance)
	m.clear()
	advancedwriter("Which option would you like to purchase?", 3, "1" , "f")
	advancedwriter("Your balance: "..formattedNumber(balance).." "..currency..pluralcurrency, 5, "1" , "f")
	
	local graytxt = "888888888888888"
	local yellowtxt = "111111111111111"
	local blackbg = "fffffffffffffffffffffffffffffffffffffffffffffffff"
	
	local firstcolor = yellowtxt..""
	local secondcolor = yellowtxt..""
	local thirdcolor = yellowtxt..""
	
	if balance < price*5 then
		thirdcolor = graytxt
		if balance < price*2 then
			secondcolor = graytxt
			if balance < price then
				firstcolor = graytxt 
			end
		end
	end
	
	m.setCursorPos(5,7)
	m.blit("###############  ###############  ###############", firstcolor.."11"..secondcolor.."11"..thirdcolor, blackbg)
	m.setCursorPos(5,8)
	m.blit("#             #  #             #  #             #", firstcolor.."11"..secondcolor.."11"..thirdcolor, blackbg)
	m.setCursorPos(5,9)
	m.blit("#"..centerer(formattedNumber(productnum).." "..Fproduct:sub(1,1),13).."#  #"..centerer(formattedNumber(productnum*2).." "..Fproduct:sub(1,1),13).."#  #"..centerer(formattedNumber(productnum*5).." "..Fproduct:sub(1,1),13).."#", firstcolor.."11"..secondcolor.."11"..thirdcolor, blackbg)
	m.setCursorPos(5,10)
	m.blit("#             #  #             #  #             #", firstcolor.."11"..secondcolor.."11"..thirdcolor, blackbg)
	m.setCursorPos(5,11)
	m.blit("#     for     #  #     for     #  #     for     #", firstcolor.."11"..secondcolor.."11"..thirdcolor, blackbg)
	m.setCursorPos(5,12)
	m.blit("#             #  #             #  #             #", firstcolor.."11"..secondcolor.."11"..thirdcolor, blackbg)
	m.setCursorPos(5,13)
	m.blit("#"..centerer(formattedNumber(price).." "..Fcurrency:sub(1,1),13).."#  #"..centerer(formattedNumber(price*2).." "..Fcurrency:sub(1,1),13).."#  #"..centerer(formattedNumber(price*5).." "..Fcurrency:sub(1,1),13).."#", firstcolor.."11"..secondcolor.."11"..thirdcolor, blackbg)
	m.setCursorPos(5,14)
	m.blit("#             #  #             #  #             #", firstcolor.."11"..secondcolor.."11"..thirdcolor, blackbg)
	m.setCursorPos(5,15)
	m.blit("###############  ###############  ###############", firstcolor.."11"..secondcolor.."11"..thirdcolor, blackbg)

	advancedwriter(Fproduct:sub(1,1).." = "..Fproduct..pluralproduct, 18, "1" , "f")
	advancedwriter(Fcurrency:sub(1,1).." = "..Fcurrency..pluralcurrency, 19, "1" , "f")
	
	advancedwriter("[Cancel]", 22, "1" , "f")

	local buttons = {} 
	buttons[1] = buttonObject(5,19,6,14,{"Option1"})
	buttons[2] = buttonObject(22,36,6,14,{"Option2"})
	buttons[3] = buttonObject(39,53,6,14,{"Option3"})
	buttons[4] = buttonObject(25,32,22,22,{"Return"})
	
	local fetchEvent = nil
	while fetchEvent == nil do
		fetchEvent = getEvent(buttons)
		if fetchEvent == "Option1" and balance >= price then
			return {true, 1}
		elseif fetchEvent == "Option2" and balance >= price*2 then
			return {true, 2}
		elseif fetchEvent == "Option3" and balance >= price*5 then
			return {true, 5}
		elseif fetchEvent == "Return" then
			return {false, 0}
		end
		fetchEvent = nil
	end
end

function CardUI()
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
			turtle.suckUp()
			if not (turtle.getItemCount(1) == 0) then
				if turtle.getItemDetail(1).name == "computercraft:disk_expanded" then
					advancedwriter("", 5, "4", "f")
					advancedwriter("Processing...", 6, "4", "f")
					advancedwriter(" ", 22, "4", "f")
				
					turtle.dropDown()
					
					rednet.broadcast("verify card "..d.getDiskID(), "CentralBank1")
					local id1, response, ptcl1 = rednet.receive("CentralBank1", 3)
					if response then
						return true
					else
						turtle.suckDown()
						turtle.dropUp()
						
						advancedwriter("Card not accepted!!", 5, "e", "f")
						advancedwriter("", 6, "4", "f")
						sleep(2)
						advancedwriter("Please insert your card into the chest,", 5, "4", "f")
						advancedwriter("then press the screen to continue.", 6, "4", "f")
						advancedwriter(" [Cancel] ", 22, "4", "f")
					end
				else
					turtle.dropUp()
				end
			end
		end	
	end		
end

function PinUI()
	m.clear()
	advancedwriter("  Enter your PIN:  ", 3, "4", "f")
	
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
		fetchEvent = getKeyEvent(buttonrows, buttons)
		if fetchEvent == "X" then
			if #typedtext == 0 then
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
				rednet.broadcast("verify pin "..d.getDiskID().." "..typedtext, "CentralBank1")
				local id1, response, ptcl1 = rednet.receive("CentralBank1", 3)
				if response then
					typedtext = ""
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
						turtle.suckDown()
						turtle.dropUp()
						return false
					else	
						typedtext = ""
						hiddentext = ""
					end
				end
			end
		end
	end
end

local cyclenum = 0
while true do
	cyclenum = cyclenum + 1
	print("[C]"..cyclenum)
	Main()
end
