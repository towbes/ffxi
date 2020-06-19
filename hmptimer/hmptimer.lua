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
_addon.name     = 'hmpTimer';
_addon.version  = '0.1.5';

require 'common'
require 'imguidef'


timerflag = true;
fullmp = false;
timetext = 'blank'
--X position of window
x = 1410
--Y position of window
y = 675
--GUI Component Variable
local variables =
{
	['var_ShowTestWindow_showfixedoverlay']             = { 1, ImGuiVar_BOOLCPP }
}

----------------------------------------------------------------------------------------------------
-- func: command
-- desc: Event called when a command was entered.
----------------------------------------------------------------------------------------------------
ashita.register_event('command', function(command, ntype)
    -- Get the arguments of the command..
    local args = command:args();
    -- Toggle afk status on and off..
    if (args[1] == '/hmpx') then 
		x = args[2]
		print('set x to ' .. x)
        return true;
    end
    if (args[1] == '/hmpy') then 
		y = args[2]
		print('set y to ' .. y)
        return true;
    end
    return false;
end);


----------------------------------------------------------------------------------------------------
-- func: load
-- desc: Called when the addon is loaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('load', function()
	print('Use /hmpx # and /hmpy # to set the x/y coordinates of window')
    -- Initialize the custom variables..
    for k, v in pairs(variables) do
        -- Create the variable..
        if (v[2] >= ImGuiVar_CDSTRING) then 
            variables[k][1] = imgui.CreateVar(variables[k][2], variables[k][3]);
        else
            variables[k][1] = imgui.CreateVar(variables[k][2]);
        end
        
        -- Set a default value if present..
        if (#v > 2 and v[2] < ImGuiVar_CDSTRING) then
            imgui.SetVarValue(variables[k][1], variables[k][3]);
        end        
    end
end);

----------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Called when the addon is unloaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('unload', function()
    -- Cleanup the custom variables..
    for k, v in pairs(variables) do
        if (variables[k][1] ~= nil) then
            imgui.DeleteVar(variables[k][1]);
        end
        variables[k][1] = nil;
    end
end);

----------------------------------------------------------------------------------------------------
-- func: render
-- desc: Renders the addon objects.
----------------------------------------------------------------------------------------------------
ashita.register_event('render', function()
    hmpFixedOverlay();
end);

----------------------------------------------------------------------------------------------------
-- func: ShowExampleAppFixedOverlay
-- desc: Shows the example fixed overlay.
----------------------------------------------------------------------------------------------------
function hmpFixedOverlay()
    imgui.SetNextWindowPos(x, y);
    if (not imgui.Begin('Example: Fixed Overlay', variables['var_ShowTestWindow_showfixedoverlay'][1], 0, 0, 0.3, imgui.bor(ImGuiWindowFlags_NoTitleBar,ImGuiWindowFlags_NoResize,ImGuiWindowFlags_NoMove,ImGuiWindowFlags_NoSavedSettings))) then
        imgui.End();
        return;
    end

    imgui.Text('Time till tick: ' .. timetext);
    imgui.End();
end

---------------------------------------------------------------------------------------------------
-- func: outgoing_packet
-- desc: Event called when the addon is asked to handle an outgoing packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('outgoing_packet', function(id, size, data, modified, blocked)
    if (id == 0x0E8) then
		playermpp = AshitaCore:GetDataManager():GetParty():GetMemberCurrentMPP(0);
        local p = data:totable();
        if (p[5] == 0x00 and timerflag and playermpp < 100) then
			timerflag = false;
			firsttick_timer();
            ashita.timer.create('starthmpTimer', 10, 1, starthmp_timer);
		elseif (p[5] == 0x00 and timerflag and playermpp == 100) then
			timetext = 'fullmp'
        end
        if (p[5] == 0x02) then
			ashita.timer.stop('hmpTimer');
			ashita.timer.remove_timer('hmpTimer');
			ashita.timer.stop('starthmpTimer');
			ashita.timer.remove_timer('starthmpTimer');
			ashita.timer.stop('five');
			ashita.timer.remove_timer('five');
			ashita.timer.stop('four');
			ashita.timer.remove_timer('four');
			ashita.timer.stop('three');
			ashita.timer.remove_timer('three');
			ashita.timer.stop('two');
			ashita.timer.remove_timer('two');
			ashita.timer.stop('one');
			ashita.timer.remove_timer('one');
			ashita.timer.stop('six');
			ashita.timer.remove_timer('six');
			ashita.timer.stop('seven');
			ashita.timer.remove_timer('seven');
			ashita.timer.stop('eight');
			ashita.timer.remove_timer('eight');
			ashita.timer.stop('nine');
			ashita.timer.remove_timer('nine');
			ashita.timer.stop('ten');
			ashita.timer.remove_timer('ten');
			ashita.timer.stop('eleven');
			ashita.timer.remove_timer('eleven');
			ashita.timer.stop('twelve');
			ashita.timer.remove_timer('twelve');
			ashita.timer.stop('thirteen');
			ashita.timer.remove_timer('thirteen');
			ashita.timer.stop('fourteen');
			ashita.timer.remove_timer('fourteen');
			ashita.timer.stop('fifteen');
			ashita.timer.remove_timer('fifteen');
			ashita.timer.stop('sixteen');
			ashita.timer.remove_timer('sixteen');
			ashita.timer.stop('seventeen');
			ashita.timer.remove_timer('seventeen');
			ashita.timer.stop('eighteen');
			ashita.timer.remove_timer('eighteen');
			ashita.timer.stop('nineteen');
			ashita.timer.remove_timer('nineteen');
        end
    end
    return false;
end);

function firsttick_timer()
	ashita.timer.create('tick', 20, 1, print_tick);
	ashita.timer.create('nineteen', 1, 1, print_nineteen);
	ashita.timer.create('eighteen', 2, 1, print_eighteen);
	ashita.timer.create('seventeen', 3, 1, print_seventeen);
	ashita.timer.create('sixteen', 4, 1, print_sixteen);
	ashita.timer.create('fifteen', 5, 1, print_fifteen);
	ashita.timer.create('fourteen', 6, 1, print_fourteen);
	ashita.timer.create('thirteen', 7, 1, print_thirteen);
	ashita.timer.create('twelve', 8, 1, print_twelve);
	ashita.timer.create('eleven', 9, 1, print_eleven);
	ashita.timer.create('ten', 10, 1, print_ten);
	ashita.timer.create('nine', 11, 1, print_nine);
	ashita.timer.create('eight', 12, 1, print_eight);
	ashita.timer.create('seven', 13, 1, print_seven);
	ashita.timer.create('six', 14, 1, print_six);
	ashita.timer.create('five', 15, 1, print_five);
	ashita.timer.create('four', 16, 1, print_four);
	ashita.timer.create('three', 17, 1, print_three);
	ashita.timer.create('two', 18, 1, print_two);
	ashita.timer.create('one', 19, 1, print_one);
	timerflag = true;
end;

function starthmp_timer()
    ashita.timer.create('hmpTimer', 10, 10, hmp_timer);
end;

function hmp_timer()
	if (playermpp < 100) then
		ashita.timer.create('tick', 10, 1, print_tick);
		ashita.timer.create('nine', 1, 1, print_nine);
		ashita.timer.create('eight', 2, 1, print_eight);
		ashita.timer.create('seven', 3, 1, print_seven);
		ashita.timer.create('six', 4, 1, print_six);
		ashita.timer.create('five', 5, 1, print_five);
		ashita.timer.create('four', 6, 1, print_four);
		ashita.timer.create('three', 7, 1, print_three);
		ashita.timer.create('two', 8, 1, print_two);
		ashita.timer.create('one', 9, 1, print_one);
	else
		timetext = 'full mp'
	end
end;

function print_tick()
	timetext = 'tick'
end;

function print_one()
	timetext = 1;
end;

function print_two()
	timetext = 2;
end;

function print_three()
	timetext = 3;
end;

function print_four()
	timetext = 4;
end;

function print_five()
	timetext = 5;
end;

function print_six()
	timetext = 6;
end;

function print_seven()
	timetext = 7;
end;

function print_eight()
	timetext = 8;
end;

function print_nine()
	timetext = 9;
end;

function print_ten()
	timetext = 10;
end;

function print_eleven()
	timetext = 11;
end;

function print_twelve()
	timetext = 12;
end;

function print_thirteen()
	timetext = 13;
end;

function print_fourteen()
	timetext = 14;
end;

function print_fifteen()
	timetext = 15;
end;

function print_sixteen()
	timetext = 16;
end;

function print_seventeen()
	timetext = 17;
end;

function print_eighteen()
	timetext = 18;
end;

function print_nineteen()
	timetext = 19;
end;