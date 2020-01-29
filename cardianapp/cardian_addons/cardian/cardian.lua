-- Copyright © 2018, Stephen Kinnett
-- All rights reserved.

-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:

    -- * Redistributions of source code must retain the above copyright
      -- notice, this list of conditions and the following disclaimer.
    -- * Redistributions in binary form must reproduce the above copyright
      -- notice, this list of conditions and the following disclaimer in the
      -- documentation and/or other materials provided with the distribution.
    -- * Neither the name of Cardian nor the
      -- names of its contributors may be used to endorse or promote products
      -- derived from this software without specific prior written permission.

-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL Stephen Kinnett BE LIABLE FOR ANY
-- DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

_addon.author   = 'Stephen Kinnett'; -- ported to Ashita by towbes
_addon.name     = 'Cardian';
_addon.version  = '0.0.1';

require 'common'

--Calculates local folder based upon file path minus file name
file_path = debug.getinfo(1, 'S')
file_path = string.gsub(file_path.source, "cardian.lua", "")
file_path = file_path:sub(2)

--Initialization variables
chat_log = {}
self_chat_log = nil
cardian_total = 1
cardian_number = 1
new_cardian_data = true
new_input = {}
screenshot_name = nil
screenshot_name_delay_1 = nil
player_name = AshitaCore:GetDataManager():GetParty():GetMemberName(0)
__debug = false;

--os.execute(PATH_TO_CARDIAN_BOT_FOLDER:sub(1,2) .. ' && cd '.. PATH_TO_CARDIAN_BOT_FOLDER ..' && luvit cardian_bot.lua')
--windower.execute(file_path .. 'discord_bot_start.bat')

--Runs upon receipt of message
function display_message (message, m_sender, m_type, m_gm)
	--Removes non-standard characters
	message = message:gsub("[^%z\1-\127]", "?")
	m_sender = m_sender:gsub("[^%z\1-\127]", " ")
	--Processes SHOUT messages
	if (m_type == 26) then
		local exists = ashita.file.file_exists('to_discord.txt')
		if exists ~= false then
			f=io.open(file_path .. "to_discord.txt","a")
			--Formats send and shout to single line including routing info and Discord formatting data
			f:write("sh__**" .. m_sender .. "**__:  ```" .. message .. "```\n")
			f:close()
		else
			f = io.open(file_path .. 'to_discord.txt')
			f:write("sh__**" .. m_sender .. "**__:  ```" .. message .. "```\n")
			f:close()
		end
	--Processes LINKSHELL messages
	elseif (m_type == 5) then
		local exists = ashita.file.file_exists('to_discord.txt')
		if exists ~= false then
			f=io.open(file_path .. "to_discord.txt","a")
			f:write("ls__**" .. m_sender .. "**__:  ```" .. message .. "```\n")
			table.insert(chat_log, '/l ' .. message)
			f:close()
		else
			f=io.open(file_path .. "to_discord.txt","a")
			f:write("ls__**" .. m_sender .. "**__:  ```" .. message .. "```\n")
			table.insert(chat_log, '/l ' .. message)
			f:close()
		end
	--Processes TELL messages
	elseif (m_type == 3) then
		local exists = ashita.file.file_exists('to_discord.txt')
		if exists ~= false then
			f=io.open(file_path .. "to_discord.txt","a")
			f:write("tl__**" .. m_sender .. "**__:  ```" .. message .. "```\n")
			f:close()
		else
			f=io.open(file_path .. "to_discord.txt","a")
			f:write("tl__**" .. m_sender .. "**__:  ```" .. message .. "```\n")
			f:close()
		end
	end
end

--Runs every time the in-game clock changes, only processes data at times ending in 0. Creates a standard starting point for all cardians
function check_timer()
--	new = tostring(new)
--	new = new:sub(new:len())
--	new = tonumber(new)
	--Enforces that changes only implement when clock ends in 0
	if new_cardian_data == true then
		--If there's a timer already running, ends it and begins a new one based upon cardian provided action frequency
		if check_timer_watch ~= nil then coroutine.close(check_timer_watch) end 
		if input_timer ~= nil then coroutine.close(input_timer) end
		new_cardian_data = false
		--Schedules data check to run at an offset based upon cardian priority list
		check_timer_watch = coroutine.schedule(check_file, (cardian_number - 1) * 3)
	end
end

--Opens to_ffxi file and processes data
function check_file()
	local f=io.open(file_path .. "to_ffxi.txt","r")
	if f~=nil then
		for line in f:lines() do
			--Checks if information is new Cardian order information. Extracts and acts upon data if so
			new_order = false
			if line:sub(8) == "=cardian_assign_order " then
				cardian_number = tonumber(line:sub(1,3))
				cardian_total = tonumber(line:sub(5,7))
				duplicate = true 
				new_cardian_data = true
				new_order = true
				print("New Cardian order information!")
			else
			--If not Cardian data, adds line to process
				if new_order == false then 
					table.insert(new_input, line)
				end
			end
		end
		--Clears file
		f:close()
		f=io.open(file_path .. "to_ffxi.txt","w+")
		f:close()
	end
	--Begins processing received data
	if new_input ~= nil then
		process_new_input()
	end
	--Schedules next file check based upon total number of active Cardians
	check_timer_watch = coroutine.schedule(check_file, (cardian_total * 3))
end

function process_new_input()
	line = new_input[1]
	if line ~= nil then
--		line = windower.to_shift_jis(line)
		line = line
		duplicate = false
		--If message is about new cardian order, takes in new data and begins switch to new timings
		--Handles (skips) duplicate messages
		if line == "SCREENSHOTREQUESTED" then print("SCREENSHOT REQUESTED!") screenshot() duplicate = true end
		for k, log_line in pairs(chat_log) do
			if log_line == line then duplicate = true end
			if k > 5 then table.remove (chat_log, 1) end
		end
		--Handles line if not duplicate data
		if duplicate == false then
			if line:sub(1,3) == "/l " then
				self_chat_log = "<" .. player_name .. "> " .. line:sub(4)
			end
			AshitaCore:GetChatManager():QueueCommand(line, 1);
		end
		--Clears processed lines from the queue
		table.remove(new_input, 1)
		if new_input ~= nil then
			if input_timer ~= nil then
				coroutine.close(input_timer)
			end
		--Schedules display of next line
		input_timer = coroutine.schedule(process_new_input, 3.5)
		end
	end
end


function screenshot()
	tmp = os.date("*t")
	screenshot_name = string.format('%s_%04d.%02d.%02d_%02d%02d%02d', player_name, tmp.year, tmp.month, tmp.day, tmp.hour, tmp.min, tmp.sec)
	screenshot_name_delay_1 = string.format('%s_%04d.%02d.%02d_%02d%02d%02d', player_name, tmp.year, tmp.month, tmp.day, tmp.hour, tmp.min, tmp.sec + 1)
	print("Screenshot name: " .. screenshot_name);
	print("Screenshot name delay: " .. screenshot_name_delay_1);
	AshitaCore:GetChatManager():QueueCommand("/screenshot png hide", 1)
	coroutine.schedule(send_screenshot, 1)
end

function send_screenshot()
	local exists = ashita.file.file_exists('to_discord.txt')
	if exists ~= false then
		f=io.open(file_path .. "to_discord.txt","a")
		f:write("SCREENSHOTRETURNED".. screenshot_name .."\n")
		f:write("SCREENSHOTRETURNED".. screenshot_name_delay_1 .."\n")
		f:close()
	else
		f=io.open(file_path .. 'to_discord.txt',"a")
		f:write("SCREENSHOTRETURNED" .. screenshot_name .. "\n")
		f:write("SCREENSHOTRETURNED".. screenshot_name_delay_1 .."\n")
	end
end


----------------------------------------------------------------------------------------------------
-- func: command
-- desc: Event called when a command was entered.
----------------------------------------------------------------------------------------------------
ashita.register_event('command', function(command, ntype)
    -- Get the arguments of the command..
    local args = command:args();
    if (args[1] == '/name') then
		print("Name: " .. player_name);
        return true;
    end

	--Toggles debug flag
	if (args[1] == '/discorddebug') then
		if (__debug) then
			print("Debug off");
			__debug = false;
		else
			print("Debug on");
			__debug = true;
		end
		return false;
	end	
	
	return false;
end);



ashita.register_event('load', function()
    print('Discord timer started');
	--Start a timer to check file, pulses every 10 seconds
	ashita.timer.create('file_timer', 10, 0, check_timer);

end);

---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Event called when the addon is asked to handle an incoming packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, data, modified, blocked)
    if (id == 0x0017) then
        local chatmode = struct.unpack('B',data, 0x04 + 1);		
		local sender = struct.unpack('s', data, 0x08 + 1);
		local gmflag = struct.unpack('B', data, 0x05 + 1);
		local message = struct.unpack('s', data, 0x18 + 1);
		display_message(message, sender, tonumber(chatmode), gmflag);
    end
    return false;
end);

ashita.register_event('outgoing_text', function(mode, message, modifiedmode, modifiedmessage, blocked)
    print('Outgoing text event fired!');
    return false;
end);

coroutine.close = function(co)
end

coroutine.schedule = function(fn, time)
    local co = coroutine.create(fn)
    ashita.timer.once(time, coroutine.resume, co)
    return co
end

coroutine.sleep = function(time)
    local co = coroutine.running()
    ashita.timer.once(time, coroutine.resume, co)
    coroutine.yield()
end