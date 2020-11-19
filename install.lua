--Code @ https://pastebin.com/uQHKLREv

local initURL = "https://raw.githubusercontent.com/SOLEHUNTER/ComputerCraftPrograms/master/programs/init.lua"
local init, initFile
 
fs.makeDir("programs")
 
init = http.get(initURL)
initFile = init.readAll()
 
local fileinit = fs.open("programs/init", "w")
fileinit.write(initFile)
fileinit.close()
