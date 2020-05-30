_addon.author 	= 'towbes';
_addon.name		= 'wscount';
_addon.version 	= '0.0.1';
require 'common'


local wscount = 0;
--WS is case sensitive as it appears in chat
local weaponskill = 'Hot Shot'


ashita.register_event('load', function()
	print(string.format('Starting ws count for %s' ,weaponskill));
end );
ashita.register_event('incoming_text', function(mode, message, modifiedmode, modifiedmessage, blocked)
	if message:contains('uses ' .. weaponskill) then
		wscount = wscount + 1
		print('New ws count: ' .. wscount);
	end
    return false;
end);
ashita.register_event('command', function(cmd, nType)
    local args = cmd:args();    
	if (args[1] == '/wscount') then
		print(string.format('Current count [%d]',wscount));
		return true;
	end
	if (#args == 2 and args[1] == '/wscount' and args[2] == 'reset') then
		wscount = 0
		print("reset ws count")
		return true;
	end
	if (#args == 2 and args[1] == '/wscount') then
		weaponskill = args[2]
		print("Changed weaponskill to " .. weaponskill)
		return true;
	end
	return false;
end );
