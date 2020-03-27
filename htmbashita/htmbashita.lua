_addon.name = 'HTMB Ashita'

_addon.author = 'towbes'

_addon.version = '0.1'

require 'common'
require 'ffxi.recast'
require 'logging'
require 'timer'

buyQueue = { };  -- Table to hold commands queued for sending
objDelay        = 0.65; -- The delay to prevent spamming packets.
objTimer        = 0;    -- The current time used for delaying packets.
busy = false
insideMenu = false
pkt = {};
__debug = false



htmb_map = {
     [0] = {name = 'Shadow Lord phantom gem',      cost = 10},
     [1] = {name = 'Stellar Fulcrum phantom gem',  cost = 10},
     [2] = {name = 'Celestial Nexus phantom gem',  cost = 10},
     [3] = {name = 'Phantom gem of apathy',        cost = 15},
     [4] = {name = 'Phantom gem of arrogance',     cost = 15},
     [5] = {name = 'Phantom gem of envy',          cost = 15},
     [6] = {name = 'Phantom gem of cowardice',     cost = 15},
     [7] = {name = 'Phantom gem of rage',          cost = 15},
     [8] = {name = 'P. Perpetrator phantom gem',   cost = 20},
     [9] = {name = 'Savage\'s phantom gem',        cost = 10},
    [10] = {name = 'Warrior\'s Path phantom gem',  cost = 10},
    [11] = {name = 'Puppet in Peril phantom gem',  cost = 10},
    [12] = {name = 'Legacy phantom gem',           cost = 10},
    [13] = {name = 'Head wind phantom gem',        cost = 10},
    [14] = {name = 'Avatar phantom gem',           cost = 10},
    [15] = {name = 'Moonlit Path phantom gem',     cost = 10},
    -- page 2
    [16] = {name = 'Waking the Beast phantom gem', cost = 10},
    [17] = {name = 'Waking Dream phantom gem',     cost = 10},
    [18] = {name = 'Feared One phantom gem',       cost = 10},
    [19] = {name = 'Dawn phantom gem',             cost = 10},
    [20] = {name = 'Stygian Pact phantom gem',     cost = 10},
    [21] = {name = 'Champion phantom gem',         cost = 10},
    [22] = {name = 'Divine phantom gem',           cost = 10},
    [23] = {name = 'Maiden phantom gem',           cost = 10},
}

valid_zones = {

	[231] = {npc="Trisvain", menu=892}, -- Northern San d'Oria

	[236] = {npc="Raving Opossum", menu=429}, -- Port Bastok

	[240] = {npc="Mimble-Pimble", menu=895}, -- Port Windurst

}

menu_options = 0
merit_points = 34

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

function has_bit (mask, offset)
	DebugMessage("Checking for bit")
    return math.floor(mask/2^offset)%2 == 1
end

function get_option_index(item)
	local option = item
	if htmb_map[option] and htmb_map[option].cost > merit_points then
		print("\30\68[HTMB]You don't have enough merits");
		DebugMessage("Merit points: " .. merit_points)
		return false
	elseif htmb_map[option] and has_bit(menu_options, option) then
		DebugMessage("Found it! Option: " .. option)
		return option
	else
		DebugMessage("Could not find that KI")
		return false
	end
end	
	
ashita.register_event('command', function(cmd, nType)
	-- Get the command arguments..
    local args = cmd:args();

    if (args[1] ~= '/htmb') then
        return false;
    end

	if (#args >=2 and args[1] == '/htmb') then

		local item = args[3]:lower();
		-- /htmb buy #    <--- the index number of desired item on htmb_map *0-23
		if args[2] == 'buy' and args[3] ~= nil then

			if not busy then
				pkt = validate(item)
				if pkt then
					print("\30\68[HTMB]Poking NPC");	
					busy = true
					local pokeNpcPacket = struct.pack('I2I2I4I2I2', 0x0E1A, 0x0000, pkt['Target'], pkt['Target Index'], 0x0000):totable();
					table.insert(buyQueue, { 0x01A, pokeNpcPacket});
				end
				return true
			else
				print("\30\68[HTMB]Stuck in a menu sorry");
				return true
			end;
		end
	end
	
    -- Prints the addon help..
    print_help('/htmb', {
		{'/htmb buy #', ' Buy index number of desired item on htmb_map *0-23 (Look in LUA file)'}
    });
	return false
end);

------------------------------------------------------------------------------------------------
-- desc: Getting pup information from packets for subsequent equipment changes.
----------------------------------------------------------------------------------------------------

ashita.register_event('incoming_packet', function(id, size, packet)
	-- Party Member's Status
	if (id == 0x034) and busy and pkt then
		menu_options = struct.unpack('I4', packet, 0x0C + 1)
		merit_points = struct.unpack('b', packet, 0x10 + 1)
		insideMenu = true
		pkt['Option Index'] = get_option_index(pkt['MapId'])
		if pkt['Option Index'] then
			DebugMessage("Option index: " .. pkt['Option Index'])
			--Get from 034: Zone, Menu ID, 
			DebugMessage("Got 0x034 packet, Buying the KI")
			local startPacket = struct.pack('I2I2', 0x0416, 0x0000, GetPlayerEntity().TargetIndex, 0):totable();		
			AddOutgoingPacket(0x016, startPacket)		
			local buyPacket = struct.pack('I2I2I4bbI2I2bbI2I2', 0x0A5B, 0x0000, pkt['Target'], 0x02, pkt['Option Index'], 0x0000, pkt['Target Index'], 0x00, 0x00, pkt['Zone'], pkt['Menu ID']):totable();
			table.insert(buyQueue, { 0x05B, buyPacket});
		else
			print("\30\68[HTMB]Not enough merits or already have KI");
			local closePacket = struct.pack('I2I2I4I2I2I2bbI2I2', 0x0A5B, 0x0000, pkt['Target'], 0x0000, 0x0000, pkt['Target Index'], 0x00, 0x00, pkt['Zone'], pkt['Menu ID']):totable();
			table.insert(buyQueue, { 0x05B, closePacket});
		end
		busy = false
		return true;

	end
	return false;
end);

----------------------------------------------------------------------------------------------------
-- func: render
-- desc: Event called when the addon is being rendered.
----------------------------------------------------------------------------------------------------

ashita.register_event('render', function()
    -- Process the objectives packet queue..
    process_queue();
end);

----------------------------------------------------------------------------------------------------
-- func: process_queue
-- desc: Processes the packet queue to be sent.
----------------------------------------------------------------------------------------------------

function process_queue()
    if  (os.time() >= (objTimer + objDelay)) then
        objTimer = os.time();

        -- Ensure the queue has something to process..
        if (#buyQueue > 0) then
            -- Obtain the first queue entry..
            local data = table.remove(buyQueue, 1);
            -- Send the queued object..
            AddOutgoingPacket(data[1], data[2]);
--		elseif busy and (#buyQueue < 1) then
--			DebugMessage("Done buying, closing menu")
--			AshitaCore:GetChatManager():QueueCommand('/sendkey escape down', 1)
--			ashita.timer.once(0.1, escape_up)
--			busy = false
--			insideMenu = false
        end
    end
end

function escape_up ()
	AshitaCore:GetChatManager():QueueCommand('/sendkey escape up', 1)	
end

function validate(item)
	local zone = AshitaCore:GetDataManager():GetParty():GetMemberZone(0);
	local me,target_index,target_id,distance;
	local result = {};
	DebugMessage("Checking item #" .. item)
	if valid_zones[zone] then
		for x = 0, 2303 do
			local e = GetEntity(x);
			if (e ~= nil and e.WarpPointer ~= 0) then
				if (e.Name == GetPlayerEntity().Name) then
					DebugMessage("Found me")
					result['me'] = i;
				elseif e.Name == valid_zones[zone].npc then
					DebugMessage("Found the zone")
					target_index = e.TargetIndex;
					target_id = e.ServerId;
					result['Menu ID'] = valid_zones[zone].menu;	
					DebugMessage("Menu ID: " .. result['Menu ID'])
					npc_name = e.Name;			
					distance = e.Distance;
				end;
			end
		end
	
		if math.sqrt(distance) < 15 then
			DebugMessage("NPC Found, searching for item")
			local ite = htmb_map[tonumber(item)]
			DebugMessage("Item is " .. ite.name)
			if ite then
				result['MapId'] = tonumber(item)
				result['Target'] = target_id;
				DebugMessage("Target ID: " .. result['Target'])
				--Do math for option index to get quantity of powders
				result['Option Index'] = 0
				DebugMessage("Option Index: " .. result['Option Index'])
				result['Target Index'] = target_index;
				DebugMessage("Target Index: " .. result['Target Index'])
				result['Zone'] = zone;
				DebugMessage("Zone: " .. result['Zone'])
			end;
		else
			print("\30\68[Sparks]Too far from npc");
		end
	else
		print("\30\68[Sparks]Not in a zone with a htmb npc");
	end;

	if result['Zone'] == nil then result = nil end;
	return result;
end


function DebugMessage(message)
  if __debug then
    print("\31\200[\31\05HTMB\31\200]\31\207 " .. message)
  end
end
