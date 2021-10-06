local arguments = {...}
local data = {}

local partners = {54, 56, 57}
local exchanges = {51,59}

local shops = {64}
local shopowners = {"22"}

local computernum = arguments[1]
local twinA, twinB

shell.run("clear")
print("Computer "..computernum)
rednet.open("back")

if computernum == "1" then
	local id, msg, ptcl = rednet.receive("CentralBank2")
	if id == partners[2] and msg == "Startup" then
		rednet.send(partners[2], "Startup", "CentralBank1")
		twinA = 2
		print("Linked with 2")
	end
	
	rednet.send(partners[3], "Startup", "CentralBank1")
	local id, msg, ptcl = rednet.receive("CentralBank3")
	if id == partners[3] and msg == "Startup" then
		twinB = 3
		print("Linked with 3")
	end
elseif computernum == "2" then
	sleep(1)
	rednet.send(partners[1], "Startup", "CentralBank2")
	local id, msg, ptcl = rednet.receive("CentralBank1")
	if id == partners[1] and msg == "Startup" then
		twinA = 1
		print("Linked with 1")
	end

	local id, msg, ptcl = rednet.receive("CentralBank3")
	if id == partners[3] and msg == "Startup" then
		rednet.send(partners[3], "Startup", "CentralBank2")
		twinB = 3
		print("Linked with 3")
	end
else
	local id, msg, ptcl = rednet.receive("CentralBank1")
	if id == partners[1] and msg == "Startup" then
		rednet.send(partners[1], "Startup", "CentralBank3")
		twinA = 1
		print("Linked with 1")
	end
	
	rednet.send(partners[2], "Startup", "CentralBank3")
	local id, msg, ptcl = rednet.receive("CentralBank2")
	if id == partners[2] and msg == "Startup" then
		twinB = 2
		print("Linked with 2")
	end
end

function createCard(name, id, pin)
	data[#data+1] = {}
	data[#data][1] = id
	data[#data][2] = name
	data[#data][3] = pin
	data[#data][4] = 0
	
	local source = fs.open("/disk/data.txt","a")
	source.writeLine("")
	source.write(id..":"..name..":"..pin..":0")
	source.close()
	
	return true
end

function updateBalance(id, value)
	local issuccess = false
	local source = fs.open("/disk/data.txt","w")
	for i,v in ipairs(data) do
		if v[1] == id then
			v[4] = v[4] + value
			issuccess = true
		end
		if i == #data then
			source.write(v[1]..":"..v[2]..":"..v[3]..":"..v[4])
		else
			source.writeLine(v[1]..":"..v[2]..":"..v[3]..":"..v[4])
		end
	end
	source.close()
	return issuccess
end

function updatePin(id, pin)
	local issuccess = false
	local source = fs.open("/disk/data.txt","w")
	for i,v in ipairs(data) do
		if v[1] == id then
			v[3] = v[3] + pin
			issuccess = true
		end
		if i == #data then
			source.write(v[1]..":"..v[2]..":"..v[3]..":"..v[4])
		else
			source.writeLine(v[1]..":"..v[2]..":"..v[3]..":"..v[4])
		end
	end
	source.close()
	return issuccess
end

function updateID(name, pin, newid)
	local issuccess = false
	local source = fs.open("/disk/data.txt","w")
	for i,v in ipairs(data) do
		if v[2] == name and v[3] == pin then
			v[1] = v[1] + newid
			issuccess = true
		end
		if i == #data then
			source.write(v[1]..":"..v[2]..":"..v[3]..":"..v[4])
		else
			source.writeLine(v[1]..":"..v[2]..":"..v[3]..":"..v[4])
		end
	end
	source.close()
	return issuccess
end

function fetchBalance(id)
	local source = fs.open("/disk/data.txt","r")
	for i,v in ipairs(data) do
		if v[1] == id then
			source.close()
			return v[4]
		end
	end
	source.close()
end

function fetchName(id)
	local source = fs.open("/disk/data.txt","r")
	for i,v in ipairs(data) do
		if v[1] == id then
			source.close()
			return v[2]
		end
	end
	source.close()
end

function fetchID(name)
	local source = fs.open("/disk/data.txt","r")
	for i,v in ipairs(data) do
		if v[2] == name then
			source.close()
			return v[1]
		end
	end
	source.close()
end

function verifyName(name)
	local source = fs.open("/disk/data.txt","r")
	for i,v in ipairs(data) do
		if v[2] == name then
			source.close()
			return false
		end
	end
	source.close()
end

function verifyCard(id)
	local source = fs.open("/disk/data.txt","r")
	for i,v in ipairs(data) do
		if v[1] == id then
			source.close()
			return true
		end
	end
	source.close()
end

function verifyPin(id, pin)
	local source = fs.open("/disk/data.txt","r")
	for i,v in ipairs(data) do
		if v[1] == id and v[3] == pin then
			source.close()
			return true
		end
	end
	source.close()
end

function makePurchase(shopid, userid, cost)
	for i1,v1 in ipairs(shops) do
		if tostring(v1) == tostring(shopid) then
			local source = fs.open("/disk/data.txt","r")
			for i2,v2 in ipairs(data) do
				if v2[1] == userid then
					if updateBalance(shopowners[i1],cost) and updateBalance(v2,-cost) then
						source.close()
						return true
					end
				end
			end
			source.close()
		end
	end
	return false
end

if fs.exists("/disk/data.txt") then
	while true do
		local source = fs.open("/disk/data.txt","r")
		local lineout = source.readLine()
		
		local iterat = 1
		while not(lineout==nil) do
			local args = {}
			while not (lineout:find(":") == nil) do
				args[#args+1] = lineout:sub(1, lineout:find(":")-1)
				lineout = lineout:sub(lineout:find(":")+1)
			end
			args[#args+1] = lineout
		
			data[iterat] = args
			lineout = source.readLine()
			iterat = iterat + 1
		end
		source.close()
	
		local id, msg, ptcl = rednet.receive("CentralBank"..computernum)
		local verifiedtype = ""
		local verifiedleader = false
		
		for i,v in ipairs(partners) do
			if v == id then
				verifiedtype = "partner"
			end
		end
		if verifiedtype == "" then
			for i,v in ipairs(exchanges) do
				if id == v then
					verifiedtype = "exchange"
					verifiedleader = true
					break
				end
			end
		end
		if verifiedtype == "" then
			for i,v in ipairs(shops) do
				if id == v then
					verifiedtype = "vender"
					verifiedleader = true
					break
				end
			end
		end
		
		if not(verifiedtype=="")then
			local args = {} --Argument 1 is the command
			while not (msg:find(" ") == nil) do
				args[#args+1] = msg:sub(1, msg:find(" ")-1)
				msg = msg:sub(msg:find(" ")+1,#msg)
			end
			args[#args+1] = msg
			
			if args[1] == "create" and ((verifiedtype == "partner") or (verifiedtype == "exchange")) then
				local result1 = createCard(args[2], args[3], args[4])
				if verifiedleader then
					rednet.broadcast("create "..args[2].." "..args[3].." "..args[4], "CentralBank"..twinA)
					local id1, result2, ptcl1 = rednet.receive("CentralBank"..twinA, 3)
					rednet.broadcast("create "..args[2].." "..args[3].." "..args[4], "CentralBank"..twinB)
					local id2, result3, ptcl2 = rednet.receive("CentralBank"..twinB, 3)
					if result1 and result2 and result3 then
						rednet.send(id, true, "CentralBank"..computernum)
					else
						rednet.send(id, false, "CentralBank"..computernum)
					end
					print("["..id.." : Create] "..args[2].." "..args[3].." "..args[4])
				else
					rednet.send(id, true, "CentralBank"..computernum)
				end
			elseif args[1] == "update" then
				if args[2] == "balance" and ((verifiedtype == "partner") or (verifiedtype == "exchange")) then
					local result1 = updateBalance(args[3], args[4])
					if verifiedleader then
						rednet.broadcast("update balance "..args[3].." "..args[4], "CentralBank"..twinA)
						local id1, result2, ptcl1 = rednet.receive("CentralBank"..twinA, 3)
						rednet.broadcast("update balance "..args[3].." "..args[4], "CentralBank"..twinB)
						local id2, result3, ptcl2 = rednet.receive("CentralBank"..twinB, 3)
						if result1 and result2 and result3 then
							rednet.send(id, true, "CentralBank"..computernum)
						else
							rednet.send(id, false, "CentralBank"..computernum)
						end
						print("["..id.." : Update balance] "..args[3].." "..args[4].." :: "..fetchBalance(args[3]))
					else
						rednet.send(id, true, "CentralBank"..computernum)
					end
				elseif args[2] == "pin" and ((verifiedtype == "partner") or (verifiedtype == "exchange")) then
					local result1 = updatePin(args[3], args[4])
					if verifiedleader then
						rednet.broadcast("update pin "..args[3].." "..args[4], "CentralBank"..twinA)
						local id1, result2, ptcl1 = rednet.receive("CentralBank"..twinA, 3)
						rednet.broadcast("update pin "..args[3].." "..args[4], "CentralBank"..twinB)
						local id2, result3, ptcl2 = rednet.receive("CentralBank"..twinB, 3)
						if result1 and result2 and result3 then
							rednet.send(id, true, "CentralBank"..computernum)
						else
							rednet.send(id, false, "CentralBank"..computernum)
						end
						print("["..id.." : Update pin] "..args[3].." "..args[4].." :: [Security Issue]")
					else
						rednet.send(id, true, "CentralBank"..computernum)
					end
				elseif args[2] == "id" and ((verifiedtype == "partner") or (verifiedtype == "exchange")) then	
					local result1 = updateID(args[3], args[4], args[5])
					if verifiedleader then
						rednet.broadcast("update id "..args[3].." "..args[4].." "..args[5], "CentralBank"..twinA)
						local id1, result2, ptcl1 = rednet.receive("CentralBank"..twinA, 3)
						rednet.broadcast("update id "..args[3].." "..args[4].." "..args[5], "CentralBank"..twinB)
						local id2, result3, ptcl2 = rednet.receive("CentralBank"..twinB, 3)
						if result1 and result2 and result3 then
							rednet.send(id, true, "CentralBank"..computernum)
						else
							rednet.send(id, false, "CentralBank"..computernum)
						end
						print("["..id.." : Update id] "..args[3].." "..args[4].." "..args[5].." :: "..tostring(result1))
					else
						rednet.send(id, true, "CentralBank"..computernum)
					end
				end
			elseif args[1] == "get" then
				if args[2] == "balance" and ((verifiedtype == "partner") or (verifiedtype == "exchange") or (verifiedtype == "vender")) then
					local result1 = fetchBalance(args[3])
					if verifiedleader then
						rednet.broadcast("get balance "..args[3], "CentralBank"..twinA)
						local id1, result2, ptcl1 = rednet.receive("CentralBank"..twinA, 3)
						rednet.broadcast("get balance "..args[3], "CentralBank"..twinB)
						local id2, result3, ptcl2 = rednet.receive("CentralBank"..twinB, 3)
						if result1 == result2 and result2 == result3 then
							rednet.send(id, result1, "CentralBank"..computernum)
						else
							rednet.send(id, 0, "CentralBank"..computernum)
						end
						print("["..id.." : Get balance] "..args[3].." :: "..result1.." "..result2.." "..result3)
					else
						rednet.send(id, result1, "CentralBank"..computernum)
					end
				elseif args[2] == "name" and ((verifiedtype == "partner") or (verifiedtype == "exchange")) then
					local result1 = fetchName(args[3])
					if verifiedleader then
						rednet.broadcast("get name "..args[3], "CentralBank"..twinA)
						local id1, result2, ptcl1 = rednet.receive("CentralBank"..twinA, 3)
						rednet.broadcast("get name "..args[3], "CentralBank"..twinB)
						local id2, result3, ptcl2 = rednet.receive("CentralBank"..twinB, 3)
						if result1 == result2 and result2 == result3 then
							rednet.send(id, result1, "CentralBank"..computernum)
						else
							rednet.send(id, 0, "CentralBank"..computernum)
						end
						print("["..id.." : Get name] "..args[3].." :: "..result1.." "..result2.." "..result3)
					else
						rednet.send(id, result1, "CentralBank"..computernum)
					end
				elseif args[2] == "id" and ((verifiedtype == "partner") or (verifiedtype == "exchange")) then
					local result1 = fetchID(args[3])
					if verifiedleader then
						rednet.broadcast("get id "..args[3], "CentralBank"..twinA)
						local id1, result2, ptcl1 = rednet.receive("CentralBank"..twinA, 3)
						rednet.broadcast("get id "..args[3], "CentralBank"..twinB)
						local id2, result3, ptcl2 = rednet.receive("CentralBank"..twinB, 3)
						if result1 == result2 and result2 == result3 then
							rednet.send(id, result1, "CentralBank"..computernum)
						else
							rednet.send(id, 0, "CentralBank"..computernum)
						end
						print("["..id.." : Get id] "..args[3].." :: "..result1.." "..result2.." "..result3)
					else
						rednet.send(id, result1, "CentralBank"..computernum)
					end
				end
			elseif args[1] == "verify" then
				if args[2] == "card" and ((verifiedtype == "partner") or (verifiedtype == "exchange") or (verifiedtype == "vender")) then
					local result1 = verifyCard(args[3])
					if verifiedleader then
						rednet.broadcast("verify card "..args[3], "CentralBank"..twinA)
						local id1, result2, ptcl1 = rednet.receive("CentralBank"..twinA, 3)
						rednet.broadcast("verify card "..args[3], "CentralBank"..twinB)
						local id2, result3, ptcl2 = rednet.receive("CentralBank"..twinB, 3)
						if result1 and result2 and result3 then
							rednet.send(id, true, "CentralBank"..computernum)
						else
							rednet.send(id, false, "CentralBank"..computernum)
						end
						print("["..id.." : Verify card] "..args[3].." :: "..tostring(result1))
					else
						rednet.send(id, result1, "CentralBank"..computernum)
					end
				elseif args[2] == "name" and ((verifiedtype == "partner") or (verifiedtype == "exchange")) then
					local result1 = verifyName(args[3])
					if verifiedleader then
						rednet.broadcast("verify name "..args[3], "CentralBank"..twinA)
						local id1, result2, ptcl1 = rednet.receive("CentralBank"..twinA, 3)
						rednet.broadcast("verify name "..args[3], "CentralBank"..twinB)
						local id2, result3, ptcl2 = rednet.receive("CentralBank"..twinB, 3)
						if args[4] and not(result1) and not(result2) and not(result3) then
							rednet.send(id, true, "CentralBank"..computernum)
						elseif not(args[4]) and result1 and result2 and result3 then
							rednet.send(id, true, "CentralBank"..computernum)
						else
							rednet.send(id, false, "CentralBank"..computernum)
						end
						print("["..id.." : Verify name] "..args[3].." :: "..tostring(result1))
					else
						rednet.send(id, result1, "CentralBank"..computernum)
					end
				elseif args[2] == "pin" and ((verifiedtype == "partner") or (verifiedtype == "exchange") or (verifiedtype == "vender")) then
					local result1 = verifyPin(args[3], args[4])
					if verifiedleader then
						rednet.broadcast("verify pin "..args[3].." "..args[4], "CentralBank"..twinA)
						local id1, result2, ptcl1 = rednet.receive("CentralBank"..twinA, 3)
						rednet.broadcast("verify pin "..args[3].." "..args[4], "CentralBank"..twinB)
						local id2, result3, ptcl2 = rednet.receive("CentralBank"..twinB, 3)
						if result1 and result2 and result3 then
							rednet.send(id, true, "CentralBank"..computernum)
						else
							rednet.send(id, false, "CentralBank"..computernum)
						end
						print("["..id.." : Verify pin] "..args[3].." "..args[4].." :: "..tostring(result1))
					else
						rednet.send(id, result1, "CentralBank"..computernum)
					end
				end
			elseif args[1] == "completepurchase" and ((verifiedtype == "partner") or (verifiedtype == "vender")) then
				if verifiedleader then
					local result1 = makePurchase(id, args[3], args[4])
					rednet.broadcast("completepurchase "..id.." "..args[3].." "..args[4], "CentralBank"..twinA)
					local id1, result2, ptcl1 = rednet.receive("CentralBank"..twinA, 3)
					rednet.broadcast("completepurchase "..id.." "..args[3].." "..args[4], "CentralBank"..twinB)
					local id2, result3, ptcl2 = rednet.receive("CentralBank"..twinB, 3)
					if result1 and result2 and result3 then
						rednet.send(id, true, "CentralBank"..computernum)
					else
						rednet.send(id, false, "CentralBank"..computernum)
					end
					print("["..id.." : Completepurchase] "..id.." "..args[3].." "..args[4].." :: "..tostring(result1))
				else
					if makePurchase(args[2], args[3], args[4]) then
						rednet.send(id, true, "CentralBank"..computernum)
					end
				end
			end
		end
	end
end
