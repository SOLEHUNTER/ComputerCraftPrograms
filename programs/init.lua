local monitor = periphreal.find("monitor")
if monitor == null then
  error("No valid monitor was found!")
else 
  monitor.setCursorPos(1,1)
  monitor.write("Code Initialized!")
end
