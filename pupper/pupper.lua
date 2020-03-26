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
_addon.name     = 'pupper';
_addon.version  = '0.3';

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

manDelay        = 1 -- The delay to prevent spamming maneuvers , 3 seconds
manTimer        = 0;    -- The current time used for delaying packets.
castDelay 		= 10;
castTimer		= 0;
maneuvers = {};
manFlag = false;
currMan = 1;
currBuffFlag = false;
currManBuffs = {};
isMount = false;
buff1total = 1
buff2total = 1
buff3total = 1
isOverloaded = false
zoning_bool = false
DebugMode = false

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

		if man1 == man2 and man1 == man3 then
			buff1total = 3
			buff2total = 0
			buff3total = 0
		elseif man2 == man3 then
			buff1total = 1
			buff2total = 2
			buff3total = 0
		elseif man1 == man2 then
			buff1total = 2
			buff2total = 0
			buff3total = 1
		elseif man1 == man3 then
			buff1total = 2
			buff2total = 1
			buff3total = 0
		end
		

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
			currManBuffs = {manbuff1, manbuff2, manbuff3}
			printbuffs = ashita.settings.JSON:encode_pretty(currManBuffs, nil, {pretty = true, indent = "->    " });
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

		if maneuvers[1] == nil then
			print("No maneuvers set")
			return
		end

		if pet ~= nil and (MainJob == 18 or SubJob == 18) then
			manFlag = true
			print("Maneuvers going!")
		else
			print("no pet!")

		end
		
		
end;


----------------------------------------------------------------------------------------------------
-- func: process_queue
-- desc: Processes the packet queue to be sent.
----------------------------------------------------------------------------------------------------
function process_maneuver()

	if  (os.time() >= (manTimer + manDelay)) then
		manTimer = os.time();
		local recastTimerManeuver   	= ashita.ffxi.recast.get_ability_recast_by_id(210);
		-- Check if manflag is set, then try to activate maneuver
		local player = GetPlayerEntity();
		if (player == nil) then
			return;
		end
		
		-- Obtain the players pet index..
		if (player.PetTargetIndex == 0) then
			return;
		end
		
		-- Obtain the players pet..
		local pet = GetEntity(player.PetTargetIndex);
		if (pet == nil) then
			return;
		end
		if (manFlag and not currBuffFlag and recastTimerManeuver == 0 and pet ~=nil and not isMounted and not isOverloaded) then
			if (buff1total > buff1count) then
				manString = maneuvers[1] .. " Maneuver"
				AshitaCore:GetChatManager():QueueCommand('/ja "' .. manString .. '" <me>', 1)
			elseif (buff2total > buff2count) then
				manString = maneuvers[2] .. " Maneuver"
				AshitaCore:GetChatManager():QueueCommand('/ja "' .. manString .. '" <me>', 1)
			elseif (buff3total > buff3count) then	
				manString = maneuvers[3] .. " Maneuver"
				AshitaCore:GetChatManager():QueueCommand('/ja "' .. manString .. '" <me>', 1)
			end
		end
	end
end;


function do_repair()
	local recastTimerRepair   	= ashita.ffxi.recast.get_ability_recast_by_id(206);
	local inventory = AshitaCore:GetDataManager():GetInventory();
	local ammo = inventory:GetEquippedItem(3);
	if ammo.ItemIndex == 0 then
		return
	elseif recastTimerRepair == 0 and ammo.ItemIndex > 0 then
		AshitaCore:GetChatManager():QueueCommand('/ja Repair <me>', 1)
	end
end

function do_cooldown()
	local recastTimerCooldown   	= ashita.ffxi.recast.get_ability_recast_by_id(114);
	if recastTimerCooldown == 0 then
		AshitaCore:GetChatManager():QueueCommand('/ja Cooldown <me>', 1)
	end
end
----------------------------------------------------------------------------------------------------
-- func: render
-- desc: Event called when the addon is being rendered.
----------------------------------------------------------------------------------------------------
ashita.register_event('render', function()
	--track if we have the buff of current maneuver, if we do, move to next manuever
	isMounted = false
	buff1count = 0
	buff2count = 0
	buff3count = 0
	currBuffFlag = false
	
	local player = GetPlayerEntity();
	if (player == nil) then
		manFlag = false
		return;
	end
	
	if zoning_bool then
		return
	end
	
	-- Obtain the players pet index..
	if (player.PetTargetIndex == 0) then
		return;
	end
	
	-- Obtain the players pet..
	local pet = GetEntity(player.PetTargetIndex);
	if (pet == nil) then
		manFlag = false
		return;
	end
	
	petDistance = math.sqrt(pet.Distance)
	--Check pet hp, if pet hp is below 35% use repair and if pet is within 20yalms
	if pet.HealthPercent < 35 and petDistance < 20 then
		do_repair()
	end
	

	isOverloaded = false
	
	local buffs						= AshitaCore:GetDataManager():GetPlayer():GetBuffs();
	for i,v in pairs(buffs) do
		--we're mounted
		if buffs[i] == 252 then
			isMounted = true
		end
		--overloaded!
		if buffs[i] == 299 then
			do_cooldown()
			isOverloaded = true
		end
		if tonumber(currManBuffs[1]) == buffs[i] then
			buff1count = buff1count + 1
		end
		if tonumber(currManBuffs[2]) == buffs[i] then
			buff2count = buff2count + 1
		end
		if tonumber(currManBuffs[3]) == buffs[i] and buff3total == 1 then
			buff3count = buff3count + 1
		end

	end
	-- Process the objectives packet queue..
    process_maneuver();
end);

ashita.register_event(
    "incoming_packet",
    function(id, size, data)
		if (id == 0xB) then
			DebugMessage("Currently zoning.")
			zoning_bool = true
		elseif (id == 0xA and zoning_bool) then
			DebugMessage("No longer zoning.")
			zoning_bool = false
		end
        return false
    end
)

function DebugMessage(message)
    if DebugMode then
        print("\31\200[\31\05Pupper\31\200]\31\207 " .. message)
    end
end

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
	
	if (#args >= 2 and args[2] == 'test') then
		local inventory = AshitaCore:GetDataManager():GetInventory();
		local equipment = inventory:GetEquippedItem(3);
		print("ammo: " .. equipment.ItemIndex);
		return true
	end
	
    if (#args >= 2 and args[2] == 'delay') then
		print("Delay set to " .. args[3])
  		manDelay = tonumber(args[3])
  		return true;
  	end
	
    if (#args >= 2 and args[2] == 'go') then
  		do_maneuvers()
  		return true;
  	end
	
    if (#args >= 2 and args[2] == 'stop') then
		manFlag = false
		print("Maneuvers stopped!")
  		return true;
  	end
    -- Prints the addon help..
    print_help('/pupper', {
		{'/pupper set maneuver maneuver maneuver', ' - sets maneuver rotation (water, fire, ice, light, wind, earth, thunder, dark'},
		{'/pupper go', ' - starts rotation'}
		
    });
    return true;
	
end);
