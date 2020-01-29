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

_addon.name = 'Cardian'
_addon.author = 'Stephen Kinnett'
_addon.version = '0.0.0.5'

local files = require('files')
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
player_name = windower.ffxi.get_player()['name']

--os.execute(PATH_TO_CARDIAN_BOT_FOLDER:sub(1,2) .. ' && cd '.. PATH_TO_CARDIAN_BOT_FOLDER ..' && luvit cardian_bot.lua')
windower.execute(file_path .. 'discord_bot_start.bat')

--Runs upon receipt of message
function display_message (message, m_sender, m_type, m_gm)
	--Removes non-standard characters
	message = message:gsub("[^%z\1-\127]", "?")
	m_sender = m_sender:gsub("[^%z\1-\127]", " ")
	--Processes SHOUT messages
	if (m_type == 26) then
		local exists = files.exists('to_discord.txt')
		if exists ~= false then
			f=io.open(file_path .. "to_discord.txt","a")
			--Formats send and shout to single line including routing info and Discord formatting data
			f:write("sh__**" .. m_sender .. "**__:  ```" .. message .. "```\n")
			f:close()
		else
			f = files.new('to_discord.txt')
			f:write("sh__**" .. m_sender .. "**__:  ```" .. message .. "```\n")
		end
	--Processes LINKSHELL messages
	elseif (m_type == 5) then
		local exists = files.exists('to_discord.txt')
		if exists ~= false then
			f=io.open(file_path .. "to_discord.txt","a")
			f:write("ls__**" .. m_sender .. "**__:  ```" .. message .. "```\n")
			table.insert(chat_log, '/l ' .. message)
			f:close()
		else
			f = files.new('to_discord.txt')
			f:write("ls__**" .. m_sender .. "**__:  ```" .. message .. "```\n")
			table.insert(chat_log, '/l ' .. message)
		end
	--Processes TELL messages
	elseif (m_type == 3) then
		local exists = files.exists('to_discord.txt')
		if exists ~= false then
			f=io.open(file_path .. "to_discord.txt","a")
			f:write("tl__**" .. m_sender .. "**__:  ```" .. message .. "```\n")
			f:close()
		else
			f = files.new('to_discord.txt')
			f:write("tl__**" .. m_sender .. "**__:  ```" .. message .. "```\n")
		end
	end
end

--Runs every time the in-game clock changes, only processes data at times ending in 0. Creates a standard starting point for all cardians
function check_timer(new, old)
	new = tostring(new)
	new = new:sub(new:len())
	new = tonumber(new)
	--Enforces that changes only implement when clock ends in 0
	if new == 0 then
		if new_cardian_data == true then
			--If there's a timer already running, ends it and begins a new one based upon cardian provided action frequency
			if check_timer_watch ~= nil then coroutine.close(check_timer_watch) end 
			if input_timer ~= nil then coroutine.close(input_timer) end
			new_cardian_data = false
			--Schedules data check to run at an offset based upon cardian priority list
			check_timer_watch = coroutine.schedule(check_file, (cardian_number - 1) * 3)
		end
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
		line = windower.to_shift_jis(line)
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
			windower.chat.input(line)
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

--Acts upon a failed /tell message
function display_text(original, modified, original_mode, modified_mode, blocked)
	if original_mode == 123 and original:sub(3, -3) == 'Your tell was not received. The recipient is either offline or changing areas.' then
		f=io.open(file_path .. "to_discord.txt","a")
		if f ~= nil then
			f:write("tl__**ERROR**__:  ```" .. original .. "```\n")
			f:close()
		else
			f = files.new('to_discord.txt')
			f:write("tl__**ERROR**__:  ```" .. original .. "```\n")
		end
	elseif original_mode == 6 then
		duplicate = false
		if self_chat_log == modified:sub(4) then duplicate = true end
		--Handles line if not duplicate data
		if duplicate == false then
			f=io.open(file_path .. "to_discord.txt","a")
			if f ~= nil then
				f:write("ls__**" .. player_name .. "**__:  ```" .. modified:sub(4):gsub("<(.-)> ", "") .. "```\n")
				f:close()
			else
				f = files.new('to_discord.txt')
				f:write("ls__**SYSTEM**__:  ```" .. modified:sub(4) .. "```\n")
			end
		end
	end
end

function user_message(original, modified, blocked)
	if original == "!screenshot" then screenshot() end
end

function cardian_unload()
	print("Cardian unloaded!")
	local exists = files.exists('to_discord.txt')
	if exists ~= false then
		f=io.open(file_path .. "to_discord.txt","a")
		f:write("CARDIANADDONUNLOADED\n")
		f:close()
	else
		f = files.new('to_discord.txt')
		f:write("CARDIANADDONUNLOADED\n")
	end
end

function screenshot()
	tmp = os.date("*t")
	screenshot_name = string.format('img_%04d%02d%02d_%02d%02d%02d', tmp.year, tmp.month, tmp.day, tmp.hour, tmp.min, tmp.sec)
	screenshot_name_delay_1 = string.format('img_%04d%02d%02d_%02d%02d%02d', tmp.year, tmp.month, tmp.day, tmp.hour, tmp.min, tmp.sec + 1)
	windower.send_command("screenshot png hide")
	coroutine.schedule(send_screenshot, 1)
end

function send_screenshot()
	local exists = files.exists('to_discord.txt')
	if exists ~= false then
		f=io.open(file_path .. "to_discord.txt","a")
		f:write("SCREENSHOTRETURNED".. screenshot_name .."\n")
		f:write("SCREENSHOTRETURNED".. screenshot_name_delay_1 .."\n")
		f:close()
	else
		f = files.new('to_discord.txt')
		f:write("SCREENSHOTRETURNED" .. screenshot_name .. "\n")
		f:write("SCREENSHOTRETURNED".. screenshot_name_delay_1 .."\n")
	end
end

--Windower event scheduling. Tells the add-on what to look for and what to do if it sees it
windower.register_event('time change', function(new, old)
	check_timer(new, old)
end)
windower.register_event('outgoing text', user_message)
windower.register_event('chat message', display_message)
windower.register_event('incoming text', display_text)
windower.register_event('unload', cardian_unload)