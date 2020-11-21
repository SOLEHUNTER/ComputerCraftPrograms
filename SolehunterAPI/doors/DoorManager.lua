--Settings
local DoorNetwork = "MainDoor"
local DoorName = "DoorManager"

local RouterSide = "left"
local RedstoneSide = "right"

rednet.open(RouterSide) --The side the modem is on
rednet.host(DoorNetwork, DoorName)
print("NetworkPortOpened, OpeningDoorTemporarily")
redstone.setOutput(RedstoneSide, true)
sleep(4) --Opens door for 4 seconds
redstone.setOutput(RedstoneSide, false)
	
local passwordcheck = rednet.recieve(DoorNetwork, 3000) --Wait for pass for 3000 seconds
if passwordcheck then
	print("Recieved!")
	redstone.setOutput(RedstoneSide, true)
	sleep(4)
	redstone.setOutput(RedstoneSide, false)
else
	print("Did not Recieve.")
end
