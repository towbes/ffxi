_addon.author   = 'Shinzaru - edited by towbes';
_addon.name     = 'AutoMove';
_addon.version  = '1.0.0';

require 'common'
require ('autofollow');

local afObj = autoFollow;
local recording = false;
local dataManager = AshitaCore:GetDataManager();
local chatManager = AshitaCore:GetChatManager();
local currFilename = ""
local recordName = "Default";
local currFile;
local currPath = {};
local currPathIndex = 1;

ashita.register_event('load', function()
    afObj.baseAddress = ashita.memory.read_int32(ashita.memory.find("FFXiMain.dll", 0, "F6C4447A42D905????????D81D????????", 7, 0)); 
	if (afObj.baseAddress) then
		-- Do nothing; Addon was able to load
	else
		print("Unable to find autofollow pointer");
		chatManager:QueueCommand("/addon unload autoplayer", 1);
	end;
end);

ashita.register_event('unload', function()
	if (afObj.baseAddress) then
		afObj:setAutoRun(false);
		afObj:setDirection(0, 0, 0);
	else
		-- Do nothing; Wasn't able to attain address
	end;
end);

ashita.register_event('incoming_packet', function(id, size, data)

	
    return false;
end);

ashita.register_event('render', function()	
	local currX = dataManager:GetEntity():GetLocalX(dataManager:GetParty():GetMemberTargetIndex(0));
	local currZ = dataManager:GetEntity():GetLocalZ(dataManager:GetParty():GetMemberTargetIndex(0));
	
	
	if  (os.time() >= (afObj.timer + afObj.delay)) then
        afObj.timer = os.time();		
		
		-- Do something every .10 seconds
		if (recording) then
			table.insert(currPath, {currX, currZ});
		end;
		
		-- Check NPC actions; battle acctions; etc
	end;

	-- Has to be ran faster than timing loop
	if (afObj.running and currPathIndex <= table.getn(currPath)) then		
		local dist = math.sqrt(math.pow((currX - currPath[currPathIndex][1]), 2.0) + math.pow((currZ - currPath[currPathIndex][2]), 2.0));
		--print(dist);
		if (dist > 0.5 and dist < 30) then
			afObj:runTowards(currX, currZ, currPath[currPathIndex][1], currPath[currPathIndex][2]);
		elseif (dist < 0.5) then
			currPathIndex = currPathIndex + 1;
		else
			currPathIndex = 1;
			afObj.running = false;
			afObj:setAutoRun(false);
			print("Unable to get to path");
		end;
	elseif (afObj.running and currPathIndex > table.getn(currPath)) then
		afObj.running = false;
		afObj:setAutoRun(false);
	end;
end);

ashita.register_event('command', function(cmd, nType)
	local args = cmd:args();
	if (cmd == "/ap test") then
		print(string.format("Current Address: %x", afObj.baseAddress));
		print(afObj:getDirectionString());
		print(string.format("Saving current routes to: %s", dataManager:GetParty():GetMemberName(0) .. "-" .. dataManager:GetParty():GetMemberZone(0) .. "-" .. recordName .. ".json"));
	elseif (args[3] == "set") then -- command /ap record set name
		print("arg4 = " .. args[4]);
		currFilename = args[4] .. ".json";
	elseif (cmd == "/ap record") then
		if (recording) then
			print("Stopping route record");
			recording = false;
			
			ashita.file.create_dir(_addon.path .. '/paths/');
			if currFilename == "" then
				currFilename = dataManager:GetParty():GetMemberName(0) .. "-" .. dataManager:GetParty():GetMemberZone(0) .. "-" .. recordName .. ".json";
			end;
			currFile = io.open(_addon.path .. '/paths/' .. currFilename, 'w');
			if (currFile == nil) then
				print('Failed to write path');
			else			
				for i = 1, table.getn(currPath) do
					local currCoord = string.format("%.03f,%.03f;", currPath[i][1], currPath[i][2]);
					currFile:write(currCoord);
					currFile:write("\n");
				end;
				currFile:close();
			end;
		else
			currPath = {};
			print("Recording route");
			recording = true;
		end;
	elseif (args[2] == "load") then -- /ap load
		currPath = {};
		currFilename = args[3] .. ".json"
		print("currFilename: " .. currFilename);
		if (ashita.file.file_exists(_addon.path .. '/paths/' .. currFilename) == false) then
			print("Unable to load path");
			return true;
		else
			currFile = io.open(_addon.path .. '/paths/' .. currFilename, 'r');
			local index = 1;
			for line in currFile:lines() do
				--p(string.format('line[%s]',line));
				if line == "\n" then
					print("End of file");
				else
					local coord;
					coord = line;
					x, z = coord:match("([^,]+),([^,;]+)")
					table.insert(currPath, {tonumber(x), tonumber(z)});
				end
				index = index+1
			end
			print("Loaded " .. currFilename);
		end;
	elseif (cmd == "/ap run") then
		if (afObj.running) then
			afObj.running = false;
			afObj:setAutoRun(false);
			print("Stopping route run");
		else			
			currPathIndex = 1;
			afObj.running = true;
			print("Following route");
		end;
		
	elseif (cmd == "/ap print") then
		local currX = dataManager:GetEntity():GetLocalX(dataManager:GetParty():GetMemberTargetIndex(0));
		local currZ = dataManager:GetEntity():GetLocalZ(dataManager:GetParty():GetMemberTargetIndex(0));
		print("x: " .. currX)
		print("z: " .. currZ)
	end;



    return false;
end);