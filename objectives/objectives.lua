--[[
* Ashita - Copyright (c) 2014 - 2016 atom0s [atom0s@live.com]
*
* This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
* To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/ or send a letter to
* Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
*
* By using Ashita, you agree to the above license and its terms.
*
*      Attribution - You must give appropriate credit, provide a link to the license and indicate if changes were
*                    made. You must do so in any reasonable manner, but not in any way that suggests the licensor
*                    endorses you or your use.
*
*   Non-Commercial - You may not use the material (Ashita) for commercial purposes.
*
*   No-Derivatives - If you remix, transform, or build upon the material (Ashita), you may not distribute the
*                    modified material. You are, however, allowed to submit the modified works back to the original
*                    Ashita project in attempt to have it added to the original project.
*
* You may not apply legal terms or technological measures that legally restrict others
* from doing anything the license permits.
*
* No warranties are given.
]]--

_addon.author   = 'towbes';
_addon.name     = 'objectives';
_addon.version  = '0.3.1';



--Used for copycat mode to get/remove RoE from dual box characters with /ms send
partylist = {'Maikosae'}


---------------------------------
--DO NOT EDIT BELOW THIS LINE
---------------------------------

require 'common';

local __debug = false;
local __write = false;
local __copycat = false;

_roe = T{
	active = T{},
	complete = T{},
	max_count = 30,
};



--------------------------------------------------------------
-- Create a table for holding profiles
--------------------------------------------------------------
objectiveProfiles = { };

--------------------------------------------------------------
-- Create a table for holding the current profile to be written
--------------------------------------------------------------
currentProfile = { };

--try to load objectives file when addon is loaded
ashita.register_event('load', function()
    load_objectives();
end);

----------------------------------------------------------------------------------------------------
-- func: print_help
-- desc: Displays a help block for proper command usage.
----------------------------------------------------------------------------------------------------
local function print_help(cmd, help)
    -- Print the invalid format header..
    print('\31\200[\31\05' .. _addon.name .. '\31\200]\30\01 ' .. '\30\68Invalid format for command:\30\02 ' .. cmd .. '\30\01'); 

    -- Loop and print the help commands..
    for k, v in pairs(help) do
        print('\31\200[\31\05' .. _addon.name .. '\31\200]\30\01 ' .. '\30\68Syntax:\30\02 ' .. v[1] .. '\30\71 ' .. v[2]);
    end
end

---------------------------------------------------------------------------------------------------
-- func: clean_str
-- desc: Cleans a string of auto-translate and color tags.
---------------------------------------------------------------------------------------------------
local function clean_str(str)
    -- Parse auto-translate tags..
    str = ParseAutoTranslate(str, true);

    -- Strip the string of color tags..
    str = (str:gsub('[' .. string.char(0x1E, 0x1F, 0x7F) .. '].', ''));

    -- Strip the string of auto-translate tags..
    str = (str:gsub(string.char(0xEF) .. '[' .. string.char(0x27) .. ']', '{'));
    str = (str:gsub(string.char(0xEF) .. '[' .. string.char(0x28) .. ']', '}'));

    -- Trim linebreaks from end of strings..
    while true do
        local hasN = str:endswith('\n');
        local hasR = str:endswith('\r');
        if (hasN or hasR) then
            if (hasN) then
                str = str:trimend('\n');
            end
            if (hasR) then
                str = str:trimend('\r');
            end
        else
            break;
        end
    end
        
    -- Convert mid-linebreaks to real linebreaks..
    str = (str:gsub(string.char(0x07), '\n'));
    
    return str;
end

---------------------------------------------------------------------------------------------------
-- func: string.starts
-- desc: Checks start of a string and returns true if it starts with string passed as start
---------------------------------------------------------------------------------------------------

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end


---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Event called when the addon is asked to handle an incoming data.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, data, modified, blocked)
    if (id == 0x111) then
		for k in pairs (_roe.active) do
			_roe.active[k] = nil;
		end
		for i = 1, _roe.max_count do
			--Every 4 bytes is a new RoE
			local offset = 4 + ((i - 1) * 4);
			--Get ROE id and progress
			local id = ashita.bits.unpack_be(data, offset, 0, 12);
			local progress = ashita.bits.unpack_be(data, offset, 12, 20);
			if (__debug and id ~= nil) then
				print((string.format("roe id: 0x%X , progress: 0x%X", id,progress)));
				--print((string.format("roe progress: 0x%X ", progress)));
			end
			if id > 0 then
				_roe.active[id] = progress;
			end
		end
		for k,v in pairs (_roe.active) do
			if (__debug	and _roe.active[k] ~=nil) then
				print(string.format("roe.active id and progress: 0x%X, 0x%X", k, v));
			end	
		end
		if (__debug) then
			print(string.format("Incoming packet: 0x%X ", id));
		end
	end

	return false;
end);

ashita.register_event('outgoing_packet', function(id, size, data, modified, blocked)
    if (id == 0x10C) then
		obj = struct.unpack('I4', data, 0x04 + 1);
			if (__debug) then
				print(string.format("Sent quest packet with Objective id of: 0x%X", obj));
			end
		if (copycat == true) then
			send_objectives(obj)
		end
    end
    if (id == 0x10D) then
		obj = struct.unpack('I4', data, 0x04 + 1);
			if (__debug) then
				print(string.format("Sent quest packet with Objective id of: 0x%X", obj));
			end
		if (copycat == true) then
			send_removeobjectives(obj)
		end
    end
    return false;
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_text
-- desc: Event called when the addon is asked to handle an incoming chat line.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_text', function(mode, message, modifiedmode, modifiedmessage, blocked)


	if(__write) then
		--Logs name of Regime with current packet object value
		-- Create the file name and ensure the path to it exists..
		local d = os.date('*t');
		local n = string.format('%.2u.%.2u.%.4u.log', d.month, d.day, d.year);
		local p = string.format('%s/%s/', AshitaCore:GetAshitaInstallPath(), 'roelogs');
		if (not ashita.file.dir_exists(p)) then
			ashita.file.create_dir(p);
		end
		if string.starts(message, "You have undertaken") then
			-- Append the new chat line to the file..
			local f = io.open(string.format('%s/%s', p, n), 'a');
			if (f ~= nil) then
				--change the objective ID to hex
				print("Wrote objective to file");
				objhex = string.format("%X", obj)
				--Get the regime name from chat message by getting text within quotes You have undertaken "$regime"
				cleaned = clean_str(message)
				regime = string.sub(cleaned,23,string.len(cleaned)-3)
				local t = os.date(timestamp, os.time());
				f:write('$' .. objhex .. ';' .. regime .. '\n');
				f:close();
			end
		end
	end
    
    return false;
end);

---------------------------------------------------------------------------------------------------
-- func: send_objective
-- desc: Send objective with /ms sendto characters in partylist
---------------------------------------------------------------------------------------------------
function send_objectives(objId)
	questcommand = string.format("/objectives get 0x%X", objId);
	if(__debug) then
		print(string.format("Sending objective 0x%X with /ms send", objId));
		print(questcommand)		
	end
	for i, character in ipairs(partylist) do
		print(character)
		AshitaCore:GetChatManager():QueueCommand("/ms sendto ".. character .." " .. questcommand, 1);	
	end
end;

---------------------------------------------------------------------------------------------------
-- func: send_removeobjective
-- desc: Send objective with /ms sendto characters in partylist
---------------------------------------------------------------------------------------------------
function send_removeobjectives(objId)
	questcommand = string.format("/objectives remove 0x%X", objId);
	if(__debug) then
		print(string.format("Sending objective 0x%X with /ms send", objId));
		print(questcommand)		
	end
	for i, character in ipairs(partylist) do
		print(character)
		AshitaCore:GetChatManager():QueueCommand("/ms sendto ".. character .." " .. questcommand, 1);	
	end
end;

---------------------------------------------------------------------------------------------------
-- func: load_objectives
-- desc: load RoE objectives from a file
---------------------------------------------------------------------------------------------------
function load_objectives()
    local tempCommands = ashita.settings.load(_addon.path .. '/settings/objprofiles.json');
	if tempCommands ~= nil then
		print('[Objectives][Load] Stored objective profiles found.');
		objectiveProfiles = tempCommands;		
	else
		print('[Objectives][Load] Objective profiles could not be loaded. Creating empty lists.');
		objectiveProfiles = { };
	end
end;

---------------------------------------------------------------------------------------------------
-- func: new_profile
-- desc: Creates new profile with current objectives
---------------------------------------------------------------------------------------------------
function new_profile(profileName)
	print("Saving current RoE objectives to profile " .. profileName)
	newProfile = {}
	for k,v in pairs (_roe.active) do
		convk = string.format("0x%X",k)
		convv = string.format("0x%X",v)
		if (__debug) then
			print(string.format("objeprofile id and progress: 0x%X, 0x%X", k, v));
			print(convk)
			print(convv)
		end
		table.insert(newProfile, convk)
	end
	objectiveProfiles[profileName] = newProfile;
end;

---------------------------------------------------------------------------------------------------
-- func: list_profiles
-- desc: Lists saved profiles
---------------------------------------------------------------------------------------------------
function list_profiles()
	print("Current Profiles:\n")
	printObjectives = ashita.settings.JSON:encode_pretty(objectiveProfiles, nil, {pretty = true, indent = "->    " });
	print(printObjectives);
end;

---------------------------------------------------------------------------------------------------
-- func: load_profiles
-- desc: Load profile name to table in order to add objectives
---------------------------------------------------------------------------------------------------
function load_profile(profileName)
	count = 0
	if objectiveProfiles[profileName] == nil then
		print("That profile does not exist")
		currentProfile = {}
	else
		print("Loaded profile: " .. profileName);
		for k,v in pairs (objectiveProfiles[profileName]) do
			table.insert(currentProfile,v)
		end
	end
end;

---------------------------------------------------------------------------------------------------
-- func: get_current
-- desc: Gets the currently loaded profile objectives
---------------------------------------------------------------------------------------------------
function get_current()
	i = 0;
	for i, objective in ipairs (currentProfile) do
		i = i + 1;
		objget = string.format("0x%X",objective);
		ashita.timer.once(i, get_objective, objget);
	end
end;

---------------------------------------------------------------------------------------------------
-- func: remove_current
-- desc: Removes the currently loaded profile objectives
---------------------------------------------------------------------------------------------------
function remove_current()
	i = 0;
	for i, objective in ipairs (currentProfile) do
		i = i + 1;
		objrem = string.format("0x%X",objective);
		ashita.timer.once(i, remove_objective, objremove);
	end
end;

---------------------------------------------------------------------------------------------------
-- func: save_objectives
-- desc: saves current RoE objectives to a file
---------------------------------------------------------------------------------------------------
function save_objectives()
	print("Writing saved profiles to file settings/objprofiles.json");
	-- Save the addon settings to a file (from the addonSettings table)
	ashita.settings.save(_addon.path .. '/settings'  
						 .. '/objprofiles.json' , objectiveProfiles);
end;

---------------------------------------------------------------------------------------------------
-- func: clear_objectives
-- desc: Clears all current objectives
---------------------------------------------------------------------------------------------------
function clear_objectives()
	print("Clearing all objectives without progress...");
	i = 1
	for k,v in pairs (_roe.active) do
		if (v == 0) then
			objclear = string.format("0x%X",k)
			i = i + 1
			ashita.timer.once(i, remove_objective, objclear);
		end
	end
end;

---------------------------------------------------------------------------------------------------
-- func: clear_objectives
-- desc: Clears all current objectives
---------------------------------------------------------------------------------------------------
function clear_allobjectives()
	print("Clearing all objectives without progress...");
	i = 1
	for k,v in pairs (_roe.active) do
		objclear = string.format("0x%X",k)
		i = i + 1
		ashita.timer.once(i, remove_objective, objclear);
	end
end;

---------------------------------------------------------------------------------------------------
-- func: get_objective
-- desc: Gets an ROE objective with specified id
---------------------------------------------------------------------------------------------------
function get_objective(objectiveId)
	if(__debug) then
		print("Registering ROE objective");
	end
	fixedobj = objectiveId;
	if string.len(objectiveId) < 6 then
		prefix = string.sub(objectiveId, 1, 2)
		suffix = string.sub(objectiveId, 3)
		if string.len(suffix) < 2 then
			padding = '000';
		elseif string.len(suffix) < 3 then
			padding = '00';
		elseif string.len(suffix) < 4 then
			padding = '0';
		end
		fixedobj = prefix .. padding .. suffix
	end
	--Send a unity ranking menu packet to look natural like we opened the menu?
--	local unityranking = struct.pack('I2I2I4', 0x1517, 0x0000, 0x0000):totable();
--	AddOutgoingPacket(0x10C, unityranking);
	local getcommand = struct.pack('I2I2I4', 0x050C, 0x0000, fixedobj):totable();
	AddOutgoingPacket(0x10C, getcommand);
end;

---------------------------------------------------------------------------------------------------
-- func: remove_objective
-- desc: Removes an ROE objective with specified id
---------------------------------------------------------------------------------------------------
function remove_objective(objectiveId)
	fixedobj = objectiveId;
	if string.len(objectiveId) < 6 then
		prefix = string.sub(objectiveId, 1, 2)
		suffix = string.sub(objectiveId, 3)
		if string.len(suffix) < 2 then
			padding = '000';
		elseif string.len(suffix) < 3 then
			padding = '00';
		elseif string.len(suffix) < 4 then
			padding = '0';
		end
		fixedobj = prefix .. padding .. suffix;
	end
	print("Removing RoE Objective " .. objectiveId)
	local getcommand = struct.pack('I2I2I4', 0x050D, 0x0000, fixedobj):totable();
	AddOutgoingPacket(0x10D, getcommand);
end;

----------------------------------------------------------------------------------------------------
-- func: command
-- desc: Event called when a command was entered.
----------------------------------------------------------------------------------------------------
ashita.register_event('command', function(command, ntype)
    -- Get the arguments of the command..
    local args = command:args();

    if (args[1] ~= '/objectives') then
        return false;
    end

    -- Get an RoE Objective
    if (#args == 3 and args[2] == 'get' and string.starts(args[3], "0x") and string.len(args[3]) <= 6) then
		get_objective(args[3]);
        return true;
    end
	
    -- Remove an RoE objective
    if (#args == 3 and args[2] == 'remove' and string.starts(args[3], "0x") and string.len(args[3]) <= 6) then
		remove_objective(args[3]);
        return true;
    end
	
	if (#args >= 2 and args[2] == 'debug') then
		if (__debug) then
			print("Debug off");
			__debug = false;
		else
			print("Debug on");
			__debug = true;
		end
		return true;
	end	
	
	if (#args >= 2 and args[2] == 'write') then
		if (__write) then
			print("Objective Writing Off");
			__write = false;
		else
			print("Objective Writing On");
			__write = true;
		end
		return true;
	end	
	
	if (#args >= 2 and args[2] == 'load') then
		load_objectives()
		return true;
	end		
	
	if (#args >= 2 and args[2] == 'save') then
		save_objectives()
		return true;
	end		

	if (#args >= 2 and args[2] == 'list') then
		list_profiles()
		return true;
	end		
	
	if (#args >= 2 and args[2] == 'copycat') then
		if copycat == true then
			copycat = false;
			print("Copycat mode disabled");
		else
			copycat = true;
			print("Copycat mode enabled");
		end
		return true;
	end	

	if (#args >= 2 and args[2] == 'clear') then
		clear_objectives()
		return true;
	end	
	
	if (#args >= 2 and args[2] == 'clearall') then
		clear_allobjectives()
		return true;
	end	

	if (#args == 3 and args[2] == 'newprofile') then
		new_profile(args[3])
		return true;
	end		
	
	if (#args == 3 and args[2] == 'getwithprofile') then
		load_profile(args[3])
		get_current()
		return true;
	end		
	
	if (#args == 3 and args[2] == 'removewithprofile') then
		load_profile(args[3])
		remove_current()
		return true;
	end		

    -- Prints the addon help..
    print_help('/objectives', {
		{'/objectives get id', ' - Gets RoE objective with id format: 0x0ABC'},
		{'/objectives remove id', ' - Removes RoE objective with id format: 0x0ABC'},
		{'/objectives debug',   '- Toggles Debug flag on or off' },
        {'/objectives write',     '- Toggles writing RoE Hex + Description to Ashita folder/roelogs' },
		{'With write enabled, hex id + description will be written to file when accepting a new RoE objective', ''},
		{'/objectives load', ' - Loads list of objective profiles from objprofiles.json'},
		{'/objectives save', ' - Saves objective profiles to objprofiles.json'},
		{'/objectives list', ' - Lists available profiles'},
		{'/objectives newprofile <profileName>', ' - Adds current RoE Objectives as new profile'},
		{'/objectives getwithprofile <profileName>', ' - Gets RoEs in the specified profile'},
		{'/objectives removewithprofile <profileName>', ' - Removes RoEs in the specified profile'},
		{'/objectives clear', ' - Clears all currently loaded objectives (must zone or add/remove an objective to initilize list'},
		{'/objectives clearall', ' - Clears all currently loaded objectives (must zone or add/remove an objective to initilize list'},
		{'/objectives copycat', ' - Enables Copycat mode. Manually getting / removing ROE on main character will use /ms sendTo to update other characters - Edit partylist at top of addon file'}
    });
    return true;

end);