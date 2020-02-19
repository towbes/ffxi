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

_addon.author   = 'tornac';
_addon.name     = 'pupatt';
_addon.version  = '1.01';

---------------------------------
--DO NOT EDIT BELOW THIS LINE
---------------------------------

require 'common'
require 'ffxi.recast'
require 'logging'

--------------------------------------------------------------
-- Create a table for holding the current profile to be written
--------------------------------------------------------------
currentManeuver = "";

manDelay        = 15 -- The delay to prevent spamming maneuvers , 3 seconds
manTimer        = 0;    -- The current time used for delaying packets.
maneuvers = {};
manFlag = false;
currMan = 1;

currentAttachments = {}; -- table for holding current attachments
pupattProfiles = { }; -- table for holding attachment profiles

manBuffs = {
	{id="300", name="fire"},
	{id="301", name="ice"},
	{id="302", name="wind"},
	{id="303", name="earth"},
	{id="304", name="thunder"},
	{id="305", name="water"},
	{id="306", name="light"},
	{id="307", name="dark"}
}


function set_maneuvers(man1, man2, man3)
		local flag1 = false
		local flag2 = false
		local flag3 = false

		for _,buff in pairs(manBuffs) do
			if buff.name == string.lower(man1) then
				manbuff1 = buff.id
				flag1 = true
			end
			if buff.name == string.lower(man2) then
				manbuff2 = buff.id
				flag2 = true
			end
			if buff.name == string.lower(man3) then
				manbuff3 = buff.id
				flag3 = true
			end
		end
	
		if (flag1 and flag2 and flag3) then
			maneuvers = {man1, man2, man3}
			print(maneuvers[1]);			
			currManBuffs = {manbuff1, manbuff2, manbuff3}
			printbuffs = ashita.settings.JSON:encode_pretty(currManBuffs, nil, {pretty = true, indent = "->    " });
			print(printbuffs);		
		else
			print("Element not found")
		end
		
end
		
function do_maneuvers()	
		local player					= GetPlayerEntity();
		local pet 						= GetEntity(player.PetTargetIndex);
		local recastTimerActivate   	= ashita.ffxi.recast.get_ability_recast_by_id(205);
		local recastTimerDeactivate   	= ashita.ffxi.recast.get_ability_recast_by_id(208);
		local recastTimerdeusex   		= ashita.ffxi.recast.get_ability_recast_by_id(115);
		local MainJob 					= AshitaCore:GetDataManager():GetPlayer():GetMainJob();
		local SubJob	 				= AshitaCore:GetDataManager():GetPlayer():GetSubJob();
		local buffs						= AshitaCore:GetDataManager():GetPlayer():GetBuffs();
		--print(MainJob, SubJob, buffs[0], limitpoints, zone_id)
		currMan = 1
		if pet ~= nil then
			currentManeuver = maneuvers[currMan]
			print("Current Maneaver:" .. maneuvers[currMan])
			print("Current buffid: " .. currManBuffs[currMan])
			manFlag = true
		else
			print("no pet!")

		end
		
		
end;

function nextManeuver()
	local buffs						= AshitaCore:GetDataManager():GetPlayer():GetBuffs();
	for i,v in pairs(buffs) do
		if tonumber(currManBuffs[currMan]) == buffs[i] then
			currMan = currMan + 1
			if currMan > 3 then
				print("Currman greater than 3, resetting to 1")
				currMan = 1
			end
			print("Found last maneuvers buff, setting next maneuver: " .. maneuvers[currMan])
			currentManeuver = maneuvers[currMan]

		end
	end
end;


----------------------------------------------------------------------------------------------------
-- func: process_queue
-- desc: Processes the packet queue to be sent.
----------------------------------------------------------------------------------------------------
function process_maneuver()
    if  (os.time() >= (manTimer + manDelay)) then
        manTimer = os.time();

        -- Check if manflag is set, then try to activate maneuver
        if (manFlag) then
            -- Obtain the first queue entry..
			manString = currentManeuver .. " Maneuver"
            -- Send the queued object..
			print("Using " .. manString)
			AshitaCore:GetChatManager():QueueCommand('/ja "' .. manString .. '" <me>', 1)
			currentManeuver = ""
			nextManeuver()
        end
    end
end


----------------------------------------------------------------------------------------------------
-- func: render
-- desc: Event called when the addon is being rendered.
----------------------------------------------------------------------------------------------------
ashita.register_event('render', function()
    -- Process the objectives packet queue..
    process_maneuver();
end);




ashita.register_event('command', function(command, ntype)
    -- Get the arguments of the command..
    local args = command:args();

    if (args[1] ~= '/pupper') then
        return false;
    end


    if (#args >= 2 and args[2] == 'set') then
  		set_maneuvers(args[3],args[4],args[5])
  		return true;
  	end
	
    if (#args >= 2 and args[2] == 'delay') then
		print("Delay set to " .. args[3])
  		manDelay = tonumber(args[3])
  		return true;
  	end
	
    if (#args >= 2 and args[2] == 'go') then
  		do_maneuvers()
		print("Maneuvers going!")
  		return true;
  	end
	
    if (#args >= 2 and args[2] == 'stop') then
  		do_maneuvers()
		manFlag = false
		print("Maneuvers stopped!")
  		return true;
  	end
	
end);
