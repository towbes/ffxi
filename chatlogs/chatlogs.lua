--[[
* Ashita - Copyright (c) 2014 - 2017 atom0s [atom0s@live.com]
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

_addon.author   = 'Updated by towbes - Original creator atom0s';
_addon.name     = 'ChatLogs';
_addon.version  = '1.0';

require 'common'

----------------------------------------------------------------------------------------------------
-- Variables
----------------------------------------------------------------------------------------------------
local name = nil;
local timestamp = '[%H:%M:%S]';

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
-- func: load
-- desc: Event called when the addon is being loaded.
---------------------------------------------------------------------------------------------------
ashita.register_event('load', function()
    -- Read and set the local player name..
    local n = AshitaCore:GetDataManager():GetParty():GetMemberName(0);
    if (n ~= nil and string.len(n) > 0) then
        name = n;
    end
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Event called when the addon is asked to handle an incoming packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, data, modified, blocked)
    -- Monitor for zone changes to get the current local player name..
    if (id == 0x000A) then
        local n = struct.unpack('s', data, 0x84 + 1);
        if (n ~= nil and string.len(n) > 0) then
            name = n;
        end
    end
	
    return false;
end);


---------------------------------------------------------------------------------------------------
-- func: incoming_text
-- desc: Event called when the addon is asked to handle an incoming chat line.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_text', function(mode, message, modifiedmode, modifiedmessage, blocked)
    -- Ignore invalid data..
    if (name == nil or string.len(message) == 0) then
        return false;
    end

    -- Create the file name and ensure the path to it exists..
    local d = os.date('*t');
    local n = string.format('%s_%.2u.%.2u.%.4u.log', name, d.month, d.day, d.year);
    local p = string.format('%s/%s/', AshitaCore:GetAshitaInstallPath(), 'chatlogs');
    if (not ashita.file.dir_exists(p)) then
        ashita.file.create_dir(p);
    end


	if (mode == 1 or mode == 2 or mode == 3 or mode == 4 or mode == 5 or mode == 6 or mode == 7 or mode == 9 or mode == 10 or mode == 11 or mode == 12 or mode == 13 or mode == 14 or mode == 15 or mode == 213 or mode == 214) then
		-- Append the new chat line to the file..
		local f = io.open(string.format('%s/%s', p, n), 'a');
		if (f ~= nil) then
			local t = os.date(timestamp, os.time());
			f:write(t .. ' ' .. clean_str(message) .. '\n');
			f:close();
		end
	end

    
    return false;
end);