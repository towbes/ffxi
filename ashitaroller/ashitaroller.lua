	--Copyright (c) 2016, Selindrile
--All rights reserved.

--Redistribution and use in source and binary forms, with or without
--modification, are permitted provided that the following conditions are met:

--    * Redistributions of source code must retain the above copyright
--      notice, this list of conditions and the following disclaimer.
--    * Redistributions in binary form must reproduce the above copyright
--      notice, this list of conditions and the following disclaimer in the
--      documentation and/or other materials provided with the distribution.
--    * Neither the name of RollTracker nor the
--      names of its contributors may be used to endorse or promote products
--      derived from this software without specific prior written permission.

--THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
--ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
--WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
--DISCLAIMED. IN NO EVENT SHALL THOMAS ROGERS BE LIABLE FOR ANY
--DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
--(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
--ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
--(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
--SOFTWARE, EVEN IFIF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

_addon.name = 'Ashita Roller'
_addon.version = '0.1'
_addon.author = 'Selindrile, thanks to: Balloon and Lorand - Ashita port by towbes - Big thanks to matix for action parsing code'

require 'common'
require 'buffsmap'
require 'job_abilities'
require 'ffxi.recast'
require 'logging'
require 'timer'

rollDelay        = 1 -- The delay to prevent spamming rolls , 3 seconds
rollTimer        = 0;    -- The current time used for delaying packets.
defaults = {}
defaults.Roll_ind_1 = 17
defaults.Roll_ind_2 = 19
defaults.showdisplay = true
defaults.displayx = nil
defaults.displayy = nil
defaults.engaged = false
zonedelay = 6
stealthy = ''
was_stealthy = ''

zoning_bool = false
lastRoll = 0
lastRollCrooked = false
midRoll = false

roll1 = 0
roll2 = 0
roll1buff = 0
roll2buff = 0
roll1name = ""
roll2name = ""
haveRoll1 = false
haveRoll2 = false
haveBust = false
canDouble = false

DebugMode = false

function DebugMessage(message)
  if DebugMode then
    print("\31\200[\31\05AutoBurst\31\200]\31\207 " .. message)
  end
end

function RollerMessage(message)
   print("\31\200[\31\05Roller\31\200]\31\207 " .. message)
end

-- Returns if the key searchkey is in t.
function table.containskey(t, searchkey)
    return rawget(t, searchkey) ~= nil
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

---------------------------------------------------------------------------------------------------
-- func: load_config
-- desc: load roller config settings
---------------------------------------------------------------------------------------------------
function load_config(file)
    local tempSettings = ashita.settings.load(_addon.path .. '/settings/' .. file .. '.json');
	if tempSettings ~= nil then
		RollerMessage('Config file found.');
		return tempSettings		
	else
		RollerMessage('Settings profiles could not be loaded. Creating empty settings.');
		tempSettings = { };
		return tempSettings
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


ashita.register_event('load', function()
	settings = load_config('default')
	
	autoroll = false

	--buffId = S{309} + S(res.buffs:english(string.endswith-{' Roll'})):map(table.get-{'en'})
	
    Rollindex = {'Fighter\'s Roll','Monk\'s Roll','Healer\'s Roll','Wizard\'s Roll','Warlock\'s Roll','Rogue\'s Roll','Gallant\'s Roll','Chaos Roll','Beast Roll',
				 'Choral Roll','Hunter\'s Roll','Samurai Roll','Ninja Roll','Drachen Roll','Evoker\'s Roll','Magus\'s Roll','Corsair\'s Roll','Puppet Roll',
				 'Dancer\'s Roll','Scholar\'s Roll','Bolter\'s Roll','Caster\'s Roll','Courser\'s Roll','Blitzer\'s Roll','Tactician\'s Roll','Allies\' Roll',
				 'Miser\'s Roll','Companion\'s Roll','Avenger\'s Roll','Naturalist\'s Roll','Runeist\'s Roll'}
				 

    rollInfo = { -- 
        [105] = {name="Chaos Roll", buffid=317, stats={6,8,9,25,11,13,16,3,17,19,31,"-4", '% Attack!', 4, 8}},
        [98] = {name="Fighter's Roll", buffid=310, stats={2,2,3,4,12,5,6,7,1,9,18,'-4','% Double-Attack!', 5, 9}},
        [101] = {name="Wizard's Roll", buffid=313, stats={4,6,8,10,25,12,14,17,2,20,30, "-10", ' MAB', 5, 9}},
        [112] = {name="Evoker's Roll", buffid=324, stats={1,1,1,1,3,2,2,2,1,3,4,'-1', ' Refresh!',5, 9}},
        [103] = {name="Rogue's Roll", buffid=315, stats={2,2,3,4,12,5,6,6,1,8,14,'-6', '% Critical Hit Rate!', 5, 9}},
        [114] = {name="Corsair's Roll", buffid=326, stats={10, 11, 11, 12, 20, 13, 15, 16, 8, 17, 24, '-6', '% Experience Bonus',5, 9}},
        [108] = {name="Hunter's Roll", buffid=320, stats={10,13,15,40,18,20,25,5,27,30,50,'-?', ' Accuracy Bonus',4, 8}},
        [113] = {name="Magus's Roll", buffid=325, stats={5,20,6,8,9,3,10,13,14,15,25,'-8',' Magic Defense Bonus',2, 6}},
        [100] = {name="Healer's Roll", buffid=312, stats={3,4,12,5,6,7,1,8,9,10,16,'-4','% Cure Potency',3, 7}},
        [111] = {name="Drachen Roll", buffid=323, stats={10,13,15,40,18,20,25,5,28,30,50,'-8',' Pet: Accuracy Bonus',4, 8}},
        [107] = {name="Choral Roll", buffid=319, stats={8,42,11,15,19,4,23,27,31,35,50,'+25', '- Spell Interruption Rate',2, 6}},
        [99] = {name="Monk's Roll", buffid=311, stats={8,10,32,12,14,15,4,20,22,24,40,'-?', ' Subtle Blow', 3, 7}},
        [106] = {name="Beast Roll", buffid=318, stats={6,8,9,25,11,13,16,3,17,19,31,'-10', '% Pet: Attack Bonus',4, 8}},
        [109] = {name="Samurai Roll", buffid=321, stats={7,32,10,12,14,4,16,20,22,24,40,'-10',' Store TP Bonus',2, 6}},
        [102] = {name="Warlock's Roll", buffid=314, stats={2,3,4,12,5,6,7,1,8,9,15,'-5',' Magic Accuracy Bonus',4, 8}},
        [115] = {name="Puppet Roll", buffid=327, stats={5,8,35,11,14,18,2,22,26,30,40,'-8',' Pet: Magic Attack Bonus',3, 7}},
        [104] = {name="Gallant's Roll", buffid=316, stats={4,5,15,6,7,8,3,9,10,11,20,'-10','% Defense Bonus', 3, 7}},
        [116] = {name="Dancer's Roll", buffid=328, stats={3,4,12,5,6,7,1,8,9,10,16,'-4',' Regen',3, 7}},
        [118] = {name="Bolter's Roll", buffid=330, stats={0.3,0.3,0.8,0.4,0.4,0.5,0.5,0.6,0.2,0.7,1.0,'-8','% Movement Speed',3, 9}},
        [119] = {name="Caster's Roll", buffid=331, stats={6,15,7,8,9,10,5,11,12,13,20,'-10','% Fast Cast',2, 7}},
        [122] = {name="Tactician's Roll", buffid=334, stats={10,10,10,10,30,10,10,0,20,20,40,'-10',' Regain',5, 8}},
        [303] = {name="Miser's Roll", buffid=336, stats={30,50,70,90,200,110,20,130,150,170,250,'0',' Save TP',5, 7}},
        [110] = {name="Ninja Roll", buffid=322, stats={4,5,5,14,6,7,9,2,10,11,18,'-10',' Evasion Bonus',4, 8}},
        [117] = {name="Scholar's Roll", buffid=329, stats={'?','?','?','?','?','?','?','?','?','?','?','?',' Conserve MP',2, 6}},
        [302] = {name="Allies' Roll", buffid=335, stats={6,7,17,9,11,13,15,17,17,5,17,'?','% Skillchain Damage',3, 10}},
        [304] = {name="Companion's Roll", buffid=337, stats={{4,20},{20, 50},{6,20},{8, 20},{10,30},{12,30},{14,30},{16,40},{18, 40}, {3,10},{30, 70},'-?',' Pet: Regen/Regain',2, 10}},
        [305] = {name="Avenger's Roll", buffid=338, stats={'?','?','?','?','?','?','?','?','?','?','?','?',' Counter Rate',4, 8}},
        [121] = {name="Blitzer's Roll", buffid=333, stats={2,3.4,4.5,11.3,5.3,6.4,7.2,8.3,1.5,10.2,12.1,'-?', '% Attack delay reduction',4, 9}},
        [120] = {name="Courser's Roll", buffid=332, stats={'?','?','?','?','?','?','?','?','?','?','?','?',' Snapshot',3, 9}},
        [391] = {name="Runeist's Roll", buffid=600, stats={'?','?','?','?','?','?','?','?','?','?','?','?',' Magic Evasion',4, 8}},
        [390] = {name="Naturalist's Roll", buffid=339, stats={'?','?','?','?','?','?','?','?','?','?','?','?',' Enhancing Magic Duration',3, 7}}
	}
	buffsmap = {
    [308] = {id=308,en="Double-Up Chance",ja="ダブルアップチャンス",enl="Double-Up Chance",jal="ダブルアップチャンス"},
    [309] = {id=309,en="Bust",ja="バスト",enl="Bust",jal="バスト"},
}, {"id", "en", "ja", "enl", "jal"}
    
	roll1 = 304
	roll2 = 106
	
	if settings.showdisplay then
		create_display(settings)
	end	
end);

----------------------------------------------------------------------------------------------------
-- func: command
-- desc: Event called when a command was entered.
----------------------------------------------------------------------------------------------------
ashita.register_event('command', function(command, ntype)
    -- Get the arguments of the command..
    local args = command:args();

    if (args[1] ~= '/roller') and args[1] ~= '/roll' then
        return false;
    end
	
	local cmd = {}
	
	cmd[1] = args[2]
	cmd[2] = args[3]
	
	if cmd[1] == 'debug' then
		DebugMessage("midRoll: " .. tostring(midRoll))

	end
	
	if cmd[1] == nil or cmd[1] == "rolls" then

		if autoroll == true then
			RollerMessage('Automatic Rolling is ON.')
		else
			RollerMessage('Automatic Rolling is OFF.')
		end
		roll1 = 304
		roll2 = 106
		RollerMessage('Roll 1: '..rollInfo[roll1].name)
		RollerMessage('Roll 2: '..rollInfo[roll2].name)
		return true
    else
		if cmd[1] == "help" then
			-- Prints the addon help..
			print_help('/roller', {
				{'/roller', ' - Shows current rolls'},
				{'roll' ,'To start or stop auto rolling type '},
				{'setroll# rollId', 'Set roll to a roll id from mapping table'},
				{'pet' , 'Set pet Rolls (Companions/Beast)'},
				{'speed', "Set Bolter's roll"}
				
			});
		elseif cmd[1] == "display" then
			if cmd[2] == nil then
				settings.showdisplay = not settings.showdisplay
				config.save(settings)
			elseif cmd[2] == 'on' or cmd[2] == 'show' then
				settings.showdisplay = true
				config.save(settings)
				RollerMessage('Display On.')
			elseif cmd[2] == 'off' or cmd[2] == 'hide' then
				settings.showdisplay = false
				config.save(settings)
				RollerMessage('Display Off.')
			else
				RollerMessage('Not a recognized display subcommand. (Show, Hide)')
			end		
		elseif cmd[1] == "engaged" then
			if cmd[2] == nil then
				settings.engaged = not settings.engaged
				config.save(settings)
			elseif cmd[2] == 'on' or cmd[2] == 'true' then
				settings.engaged = true
				config.save(settings)
				RollerMessage('Engaged Only: On.')
			elseif cmd[2] == 'off' or cmd[2] == 'false' then
				settings.engaged = false
				config.save(settings)
				RollerMessage('Engaged Only: Off.')
			else
				RollerMessage('Not a recognized engaged subcommand. (on, off)')
			end
		elseif cmd[1] == "midroll" and cmd[2] == 'off' then	
			midRoll = false
		elseif cmd[1] == "start" or cmd[1] == "go" or cmd[1] == "begin" or cmd[1] == "enable" or cmd[1] == "on" or cmd[1] == "engage" or cmd[1] == "resume" then
			zonedelay = 6
			if autoroll == false then
				midRoll = false
				autoroll = true
				RollerMessage('Enabling Automatic Rolling.')
			elseif autoroll == true then
				RollerMessage('Automatic Rolling already enabled.')
			end
		elseif cmd[1] == "stop" or cmd[1] == "quit" or cmd[1] == "end" or cmd[1] == "disable" or cmd[1] == "off" or cmd[1] == "disengage" or cmd[1] == "pause" then
			zonedelay = 6
			if autoroll == true then
				autoroll = false
				RollerMessage('Disabling Automatic Rolling.')
			elseif autoroll == false then
				RollerMessage('Automatic Rolling already disabled.')
			end
		elseif cmd[1] == "roll" then
			if cmd[2] == "roll1" then
				AshitaCore:GetChatManager():QueueCommand('/ja "'..roll1name..'" <me>', 1)
			elseif cmd[2] == "roll2" then
				AshitaCore:GetChatManager():QueueCommand('/ja "'..roll2name..'" <me>', 1)
			else
				zonedelay = 6
				if autoroll == false then
					autoroll = true
					RollerMessage('Enabling Automatic Rolling.')
				elseif autoroll == true then
					autoroll = false 
					RollerMessage('Disabling Automatic Rolling.')
				end
			end
		elseif cmd[1] == "setroll1" then
			roll1 = cmd[2]
			RollerMessage('Set Role 1 to ' .. rollInfo[roll1].name)
		elseif cmd[1] == "setroll2" then
			roll2 = cmd[2]
			RollerMessage('Set Role 2 to ' .. rollInfo[roll2].name)
		elseif cmd[1] == "melee" then
			settings.Roll_ind_1 = 12
			settings.Roll_ind_2 = 8
			RollerMessage('Setting Roll 1 to: '..roll1..'')
			RollerMessage('Setting Roll 2 to: '..roll2..'')
			config.save(settings)
			
		elseif cmd[1]:startswith('exp') or cmd[1]:startswith('cap') or cmd[1] == "cp" then
			roll1 = 304
			roll2 = 114
			roll1buff = rollInfo[roll1].buffid
			roll2buff = rollInfo[roll2].buffid
			roll1name = rollInfo[roll1].name
			roll2name = rollInfo[roll2].name
			RollerMessage('Setting Roll 1 to: '..rollInfo[roll1].name)
			RollerMessage('Setting Roll 2 to: '..rollInfo[roll2].name)
--			config.save(settings)
			
		elseif cmd[1] == "tp" or cmd[1] == "stp" then
			settings.Roll_ind_1 = 12
			settings.Roll_ind_2 = 1
			RollerMessage('Setting Roll 1 to: '..roll1..'')
			RollerMessage('Setting Roll 2 to: '..roll2..'')
			config.save(settings)
			
		elseif cmd[1] == "speed" or cmd[1] == "movespeed" or cmd[1]:startswith('bolt') then
			roll1 = 118
			roll2 = 118
			roll1buff = rollInfo[roll1].buffid
			roll2buff = rollInfo[roll2].buffid
			roll1name = rollInfo[roll1].name
			roll2name = rollInfo[roll2].name
			RollerMessage('Setting Roll 1 to: '..roll1..'')
			RollerMessage('Setting Roll 2 to: '..roll2..'')
--			config.save(settings)
			
		elseif cmd[1]:startswith('acc') or cmd[1] == "highacc" then
			settings.Roll_ind_1 = 12
			settings.Roll_ind_2 = 11
			RollerMessage('Setting Roll 1 to: '..roll1..'')
			RollerMessage('Setting Roll 2 to: '..roll2..'')
			config.save(settings)
		
		elseif cmd[1] == "ws" or cmd[1] == "wsd" then
			settings.Roll_ind_1 = 8
			settings.Roll_ind_2 = 1
			RollerMessage('Setting Roll 1 to: '..roll1..'')
			RollerMessage('Setting Roll 2 to: '..roll2..'')
			config.save(settings)
		
		elseif cmd[1] == "nuke" or cmd[1] == "burst" or cmd[1] == "matk" or cmd[1]:startswith('mag')  then
			settings.Roll_ind_1 = 4
			settings.Roll_ind_2 = 5
			RollerMessage('Setting Roll 1 to: '..roll1..'')
			RollerMessage('Setting Roll 2 to: '..roll2..'')
			config.save(settings)
		
		elseif cmd[1] == "pet" or cmd[1]:startswith("petphy") then
			roll1 = 304
			roll2 = 106
			roll1buff = rollInfo[roll1].buffid
			roll2buff = rollInfo[roll2].buffid
			roll1name = rollInfo[roll1].name
			roll2name = rollInfo[roll2].name
			RollerMessage('Setting Roll 1 to: '..roll1name..'')
			RollerMessage('Setting Roll 2 to: '..roll2name..'')
--			config.save(settings)
		
		elseif cmd[1] == "petnuke" or cmd[1]:startswith('petma') then
			settings.Roll_ind_1 = 18
			settings.Roll_ind_2 = 28
			RollerMessage('Setting Roll 1 to: '..roll1..'')
			RollerMessage('Setting Roll 2 to: '..roll2..'')
			config.save(settings)
		
		elseif cmd[1] == "roll1" then
			local rollchange = false
			if cmd[2] == nil then RollerMessage('Roll 1: '..roll1..'') return
			elseif cmd[2]:startswith("warlock") or cmd[2]:startswith("macc") or cmd[2]:startswith("magic ac") or cmd[2]:startswith("rdm") then settings.Roll_ind_1 = 5 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("fight") or cmd[2]:startswith("double") or cmd[2]:startswith("dbl") or cmd[2]:startswith("war") then settings.Roll_ind_1 = 1 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("monk") or cmd[2]:startswith("subtle") or cmd[2]:startswith("mnk") then settings.Roll_ind_1 = 2 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("heal") or cmd[2]:startswith("cure") or cmd[2]:startswith("whm") then settings.Roll_ind_1 = 3 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("wizard") or cmd[2]:startswith("matk") or cmd[2]:startswith("magic at") or cmd[2]:startswith("blm") then settings.Roll_ind_1 = 4 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("rogue") or cmd[2]:startswith("crit") or cmd[2]:startswith("thf") then settings.Roll_ind_1 = 6 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("gallant") or cmd[2]:startswith("def") or cmd[2]:startswith("pld") then settings.Roll_ind_1 = 7 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("chaos") or cmd[2]:startswith("attack") or cmd[2]:startswith("atk") or cmd[2]:startswith("drk") then settings.Roll_ind_1 = 8 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("beast") or cmd[2]:startswith("pet at") or cmd[2]:startswith("bst") then settings.Roll_ind_1 = 9 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("choral") or cmd[2]:startswith("inter") or cmd[2]:startswith("spell inter") or cmd[2]:startswith("brd") then settings.Roll_ind_1 = 10 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("hunt") or cmd[2]:startswith("acc") or  cmd[2]:startswith("rng") then settings.Roll_ind_1 = 11 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("sam") or cmd[2]:startswith("stp") or cmd[2]:startswith("store") then settings.Roll_ind_1 = 12 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("nin") or cmd[2]:startswith("eva") then settings.Roll_ind_1 = 13 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("drach") or cmd[2]:startswith("pet ac") or cmd[2]:startswith("drg") then settings.Roll_ind_1 = 14 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("evoke") or cmd[2]:startswith("refresh") or cmd[2]:startswith("smn") then settings.Roll_ind_1 = 15 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("magus") or cmd[2]:startswith("mdb") or cmd[2]:startswith("magic d") or cmd[2]:startswith("blu") then settings.Roll_ind_1 = 16 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("cor") or cmd[2]:startswith("exp") then settings.Roll_ind_1 = 17 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("pup") or cmd[2]:startswith("pet m") then settings.Roll_ind_1 = 18 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("dance") or cmd[2]:startswith("regen") or cmd[2]:startswith("dnc") then settings.Roll_ind_1 = 19 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("sch") or cmd[2]:startswith("conserve m") then settings.Roll_ind_1 = 20 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("bolt") or cmd[2]:startswith("move") or cmd[2]:startswith("flee") or cmd[2]:startswith("speed") then settings.Roll_ind_1 = 21 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("cast") or cmd[2]:startswith("fast") or cmd[2]:startswith("fc") then settings.Roll_ind_1 = 22 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("course") or cmd[2]:startswith("snap") then settings.Roll_ind_1 = 23 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("blitz") or cmd[2]:startswith("delay") then settings.Roll_ind_1 = 24 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("tact") or cmd[2]:startswith("regain") then settings.Roll_ind_1 = 25 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("all") or cmd[2]:startswith("skillchain") then settings.Roll_ind_1 = 26 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("miser") or cmd[2]:startswith("save tp") or cmd[2]:startswith("conserve t") then settings.Roll_ind_1 = 27 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("companion") or cmd[2]:startswith("pet r") then settings.Roll_ind_1 = 28 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("avenge") or cmd[2]:startswith("counter") then settings.Roll_ind_1 = 29 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("natural") or cmd[2]:startswith("enhance") or cmd[2]:startswith("duration") then settings.Roll_ind_1 = 30 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("run") or cmd[2]:startswith("meva") or cmd[2]:startswith("magic e") then settings.Roll_ind_1 = 31 config.save(settings) rollchange = true
			end
			
			if rollchange == true then
				RollerMessage('Setting Roll 1 to: '..roll1..'')
			else
				RollerMessage('Invalid roll name, Roll 1 remains: '..roll1..'')
			end

		elseif cmd[1] == "roll2" then
			local rollchange = false
			if cmd[2] == nil then RollerMessage('Roll 1: '..roll2..'') return
			elseif cmd[2]:startswith("warlock") or cmd[2]:startswith("macc") or cmd[2]:startswith("magic ac") or cmd[2]:startswith("rdm") then settings.Roll_ind_2 = 5 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("fight") or cmd[2]:startswith("double") or cmd[2]:startswith("dbl") or cmd[2]:startswith("war") then settings.Roll_ind_2 = 1 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("monk") or cmd[2]:startswith("subtle") or cmd[2]:startswith("mnk") then settings.Roll_ind_2 = 2 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("heal") or cmd[2]:startswith("cure") or cmd[2]:startswith("whm") then settings.Roll_ind_2 = 3 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("wizard") or cmd[2]:startswith("matk") or cmd[2]:startswith("magic at") or cmd[2]:startswith("blm") then settings.Roll_ind_2 = 4 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("rogue") or cmd[2]:startswith("crit") or cmd[2]:startswith("thf") then settings.Roll_ind_2 = 6 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("gallant") or cmd[2]:startswith("def") or cmd[2]:startswith("pld") then settings.Roll_ind_2 = 7 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("chaos") or cmd[2]:startswith("attack") or cmd[2]:startswith("atk") or cmd[2]:startswith("drk") then settings.Roll_ind_2 = 8 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("beast") or cmd[2]:startswith("pet at") or cmd[2]:startswith("bst") then settings.Roll_ind_2 = 9 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("choral") or cmd[2]:startswith("inter") or cmd[2]:startswith("spell inter") or cmd[2]:startswith("brd") then settings.Roll_ind_2 = 10 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("hunt") or cmd[2]:startswith("acc") or  cmd[2]:startswith("rng") then settings.Roll_ind_2 = 11 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("sam") or cmd[2]:startswith("stp") or cmd[2]:startswith("store") then settings.Roll_ind_2 = 12 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("nin") or cmd[2]:startswith("eva") then settings.Roll_ind_2 = 13 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("drach") or cmd[2]:startswith("pet ac") or cmd[2]:startswith("drg") then settings.Roll_ind_2 = 14 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("evoke") or cmd[2]:startswith("refresh") or cmd[2]:startswith("smn") then settings.Roll_ind_2 = 15 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("magus") or cmd[2]:startswith("mdb") or cmd[2]:startswith("magic d") or cmd[2]:startswith("blu") then settings.Roll_ind_2 = 16 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("cor") or cmd[2]:startswith("exp") then settings.Roll_ind_2 = 17 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("pup") or cmd[2]:startswith("pet m") then settings.Roll_ind_2 = 18 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("dance") or cmd[2]:startswith("regen") or cmd[2]:startswith("dnc") then settings.Roll_ind_2 = 19 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("sch") or cmd[2]:startswith("conserve m") then settings.Roll_ind_2 = 20 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("bolt") or cmd[2]:startswith("move") or cmd[2]:startswith("flee") or cmd[2]:startswith("speed") then settings.Roll_ind_2 = 21 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("cast") or cmd[2]:startswith("fast") or cmd[2]:startswith("fc") then settings.Roll_ind_2 = 22 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("course") or cmd[2]:startswith("snap") then settings.Roll_ind_2 = 23 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("blitz") or cmd[2]:startswith("delay") then settings.Roll_ind_2 = 24 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("tact") or cmd[2]:startswith("regain") then settings.Roll_ind_2 = 25 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("all") or cmd[2]:startswith("skillchain") then settings.Roll_ind_2 = 26 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("miser") or cmd[2]:startswith("save tp") or cmd[2]:startswith("conserve t") then settings.Roll_ind_2 = 27 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("companion") or cmd[2]:startswith("pet r") then settings.Roll_ind_2 = 28 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("avenge") or cmd[2]:startswith("counter") then settings.Roll_ind_2 = 29 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("natural") or cmd[2]:startswith("enhance") or cmd[2]:startswith("duration") then settings.Roll_ind_2 = 30 config.save(settings) rollchange = true
			elseif cmd[2]:startswith("run") or cmd[2]:startswith("meva") or cmd[2]:startswith("magic e") then settings.Roll_ind_2 = 31 config.save(settings) rollchange = true
			end
			
			if rollchange == true then
				RollerMessage('Setting Roll 2 to: '..roll2..'')
			else
				RollerMessage('Invalid roll name, Roll 2 remains: '..roll2..'')
			end
         end
        
    end
	
--	update_displaybox()

    return true;

end);

--[[
ashita.register_event('outgoing_packet', function(id, size, packet, packet_modified, blocked)
	local rollActor
	local rollID
	local playerid = AshitaCore:GetDataManager():GetParty():GetMemberServerId(0)
	local mainjob = AshitaCore:GetDataManager():GetPlayer():GetMainJob();
	
	category = struct.unpack('I2', packet, 0x0A + 1)
	
	if id==0x01A and category == 9 then
		rollActor = struct.unpack('I4', packet, 0x04 + 1)
		rollID = struct.unpack('I2', packet, 0x0C + 1)
		if rollID == 177 then return end --Snake Eye
	end
    return false;
end);
--]]
ashita.register_event('incoming_packet', function(id, size, packet, packet_modified, blocked)

	if (id == 0xB) then
		DebugMessage("Currently zoning.")
		zoning_bool = true
	elseif (id == 0xA and zoning_bool) then
		DebugMessage("No longer zoning.")
		zoning_bool = false
	end

   
   if id == 0x028 then
	   act = parse_rolls(packet)

	   if act.category == 6 and table.containskey(rollInfo, act.param) then

			rollActor = act.actor_id
			local rollID = act.param
			local rollname = act.name
			DebugMessage("Rollname: " .. rollname)
			if rollID == 177 then return end
			local rollNum = act.targets[1].actions[1].param
			DebugMessage("RollNum: " .. rollNum)
			--windower.add_to_chat(7,'rollNum: '..act.targets[1].actions[1].param..'')
			local playerid = AshitaCore:GetDataManager():GetParty():GetMemberServerId(0)
			local mainjob = AshitaCore:GetDataManager():GetPlayer():GetMainJob();
			local subjob = AshitaCore:GetDataManager():GetPlayer():GetSubJob();

			if act.actor_id == playerid then
				--If roll is lucky or 11 returns.
				if act.targets[1].actions[1].message ~= 424 then
					lastRollCrooked = false
				end
				DebugMessage("RollId: " .. rollID)	
				--DebugMessage("Lucky Number: " .. rollInfo[rollID][15])
				if rollNum == rollInfo[rollID].stats[15] or rollNum == 11 then
					DebugMessage("Lucky or 11, done!")
					lastRoll = rollNum
					midRoll = false
					return false
				end

--				if not autoroll or haveBuff('amnesia') or haveBuff('impairment') then return end
				
				if mainjob == 17 then
					local snakeRecast = ashita.ffxi.recast.get_ability_recast_by_id(197);--JAid 177 , RecastId 197
					local foldRecast = ashita.ffxi.recast.get_ability_recast_by_id(198);-- JAid 178, RecastId 198
					if snakeRecast == 0 and rollNum == 10 then
						midRoll = true
						ashita.timer.once(1, function()
							AshitaCore:GetChatManager():QueueCommand('/ja "Snake Eye <me>', 1);
						end);
						ashita.timer.once(6, function()
							AshitaCore:GetChatManager():QueueCommand('/ja Double-Up <me>', 1);
						end);
--					elseif snakeRecast == 0 and rollNum == (rollInfo[rollID][15] - 1) then
--						midRoll = true
--						ashita.timer.once(1, function()
--							AshitaCore:GetChatManager():QueueCommand('ja "Snake Eye', 1);
--						end);
--						ashita.timer.once(6, function()
--							AshitaCore:GetChatManager():QueueCommand('/ja Double-Up <me>', 1);
--						end);
					elseif snakeRecast == 0 and not lastRoll == 11 and rollNum > 6 and rollNum == rollInfo[rollID][16] then
						midRoll = true
						ashita.timer.once(1, function()
							AshitaCore:GetChatManager():QueueCommand('ja "Snake Eye', 1);
						end);
						ashita.timer.once(6, function()
							AshitaCore:GetChatManager():QueueCommand('/ja Double-Up <me>', 1);
						end);
					elseif foldRecast == 0 and not lastRollCrooked and rollNum < 9 then
						midRoll = true
						ashita.timer.once(6, function()
							AshitaCore:GetChatManager():QueueCommand('/ja Double-Up <me>', 1);
						end);
					elseif (rollNum < 6 or lastRoll == 11) and not lastRollCrooked then
						midRoll = true
						ashita.timer.once(6, function()
							AshitaCore:GetChatManager():QueueCommand('/ja Double-Up <me>', 1);
						end);
					else
						DebugMessage("Finished this roll")
						midRoll = false
						lastRoll = rollNum
					end
				elseif rollNum < 6 then
					midRoll = true
					ashita.timer.once(6, function()
						AshitaCore:GetChatManager():QueueCommand('/ja Double-Up <me>', 1);
					end);
				end
			end
		end
	end
		
	return false;
end);


function haveBuff(buffname)


	buffid  = 0
	for i, id in pairs(buffsmap) do
		if buffname ~= nil and buffsmap[i].en:lower() == buffname:lower() then
			buffid = buffsmap[i].id
		end
	end

	
	local player = GetPlayerEntity();
	if (player == nil) then
		return;
	end
	local buffs						= AshitaCore:GetDataManager():GetPlayer():GetBuffs();
	for i,v in pairs(buffs) do
		if buffs[i] == buffid then
			return true
		end
	end
	
	return false
end

Cities = {
    "Ru'Lude Gardens",
    "Upper Jeuno",
    "Lower Jeuno",
    "Port Jeuno",
    "Port Windurst",
    "Windurst Waters",
    "Windurst Woods",
    "Windurst Walls",
    "Heavens Tower",
    "Port San d'Oria",
    "Northern San d'Oria",
    "Southern San d'Oria",
	"Chateau d'Oraguille",
    "Port Bastok",
    "Bastok Markets",
    "Bastok Mines",
    "Metalworks",
    "Aht Urhgan Whitegate",
	"The Colosseum",
    "Tavanazian Safehold",
    "Nashmau",
    "Selbina",
    "Mhaura",
	"Rabao",
    "Norg",
    "Kazham",
    "Eastern Adoulin",
    "Western Adoulin",
	"Celennia Memorial Library",
	"Mog Garden",
	"Leafallia"
}

function update_displaybox()
	return
end

function doRoll()

	if  (os.time() >= (rollTimer + rollDelay)) then
		rollTimer = os.time();
		
		--if Cities:contains(res.zones[windower.ffxi.get_info().zone].english) then return end
		if not autoroll or midRoll then 
			return
		end
		if haveBuff('Sneak') or haveBuff('Invisible') then
			stealthy = true
		else
			stealthy = false
		end
		if not (stealthy == was_stealthy) then update_displaybox() end
		was_stealthy = stealthy
		if stealthy then return end
		
		local playerid = AshitaCore:GetDataManager():GetParty():GetMemberServerId(0)
		local mainjob = AshitaCore:GetDataManager():GetPlayer():GetMainJob();
		local mainjob_level = AshitaCore:GetDataManager():GetPlayer():GetMainJobLevel();
		local subjob = AshitaCore:GetDataManager():GetPlayer():GetSubJob();
		if not (mainjob == 17 or subjob == 17) then return end

	--	local status = res.statuses[windower.ffxi.get_player().status].english
		
	--	if not (((status == 'Idle') and not settings.engaged) or status == 'Engaged') then return end

		
		local snakeRecast = ashita.ffxi.recast.get_ability_recast_by_id(197);--JAid 177 , RecastId 197
		local foldRecast = ashita.ffxi.recast.get_ability_recast_by_id(198);-- JAid 178, RecastId 198
		local phantomRecast = ashita.ffxi.recast.get_ability_recast_by_id(193);-- JAid 97, RecastId 193
		local randomDealRecast = ashita.ffxi.recast.get_ability_recast_by_id(196);-- JAid 133, RecastId 196
		local doubleupRecast = ashita.ffxi.recast.get_ability_recast_by_id(194);-- JAid 123, RecastId 194
		local crookedcardsRecast = ashita.ffxi.recast.get_ability_recast_by_id(96);-- JAid 392, RecastId 96

		if mainjob == 17 and foldRecast > 0 and phantomRecast == 0 and snakeRecast > 0 and doubleupRecast == 0 and randomDealRecast == 0 then 
			DebugMessage("Starting Random Deal")
			AshitaCore:GetChatManager():QueueCommand('/ja "Random Deal" <me>', 1)
			return 
		end
		
		if mainjob == 17 and haveBust and foldRecast == 0 then 
			DebugMessage("We busted, folding")
			AshitaCore:GetChatManager():QueueCommand('/ja "Fold" <me>', 1) 
			return
		end
		
		if phantomRecast > 0 then return end

		if not haveRoll1 and not haveRoll2 then
			DebugMessage("We don't have any rolls")
			lastRoll = 0
			lastRollCrooked = false
		end
		
		if not haveRoll1 then
			DebugMessage("We don't have roll 1 buff, trying roll1")
			if mainjob == 17 and mainjob_level > 94 and crookedcardsRecast == 0 then 
				ashita.timer.once(1, function()
					AshitaCore:GetChatManager():QueueCommand('/ja "Crooked Cards" <me>', 1);
				end);
				ashita.timer.once(4, function()
					AshitaCore:GetChatManager():QueueCommand('/ja "'..roll1name..'" <me>', 1);
				end);
			else
				AshitaCore:GetChatManager():QueueCommand('/ja "'..roll1name..'" <me>', 1)
			end
		elseif not haveRoll2 and not haveBust then
			DebugMessage("We don't have roll 2 buff, trying roll2")
			AshitaCore:GetChatManager():QueueCommand('/ja "'..roll2name..'" <me>', 1)
		end
	end
end

ashita.register_event('render', function()

	local player = GetPlayerEntity();
	if (player == nil) then
		zonedelay = 0
		autoroll = false
		lastRoll = 0
		lastRollCrooked = false
		update_displaybox()
		return;
	end
	
	if zoning_bool then
		return
	end
	
	haveRoll1 = false
	haveRoll2 = false
	haveBust = false
	

	local buffs						= AshitaCore:GetDataManager():GetPlayer():GetBuffs();
	for i,v in pairs(buffs) do
		--we're mounted
		if buffs[i] == 601 then -- We have crooked roll buff
			lastRollCrooked = true
		end
		if buffs[i] == roll1buff then
			haveRoll1 = true
		end
		if buffs[i] == roll2buff then
			haveRoll2 = true
		end	
		if buffs[i] == 309 then
			haveBust = true
		end	
	end
	
	doRoll()
end);


--[[
windower.register_event('job change', function()
	zonedelay = 0
	autoroll = false
	lastRoll = 0
	lastRollCrooked = false
	update_displaybox()
end)

function create_display(settings)
    if displayBox then displayBox:destroy() end

    local windowersettings = windower.get_windower_settings()
	local x,y
	
	if settings.displayx and settings.displayy then
		x = settings.displayx
		y = settings.displayy
	elseif windowersettings["ui_x_res"] == 1920 and windowersettings["ui_y_res"] == 1080 then
		x,y = windowersettings["ui_x_res"]-505, windowersettings["ui_y_res"]-18 -- -285, -18
	else
		x,y = 0, windowersettings["ui_y_res"]-17 -- -285, -18
	end
	
    displayBox = texts.new()
    displayBox:pos(x,y)
    displayBox:font('Arial')--Arial
    displayBox:size(12)
    displayBox:bold(true)
    displayBox:bg_alpha(0)--128
    displayBox:right_justified(false)
    displayBox:stroke_width(2)
    displayBox:stroke_transparency(192)

    update_displaybox(displayBox)
end

function update_displaybox()
	local player = windower.ffxi.get_player()
	if not player then return end
	if not settings.showdisplay or not (mainjob == 17 or subjob == 17) then
		if displayBox then displayBox:hide() end
		return		
	end
	
    -- Define colors for text in the display
    local clr = {
        h='\\cs(255,192,0)', -- Yellow for active booleans and non-default modals
		w='\\cs(255,255,255)', -- White for labels and default modals
        n='\\cs(192,192,192)', -- White for labels and default modals
        s='\\cs(96,96,96)' -- Gray for inactive booleans
    }

    local info = {}
    local orig = {}
    local spc = '   '

    -- Define labels for each modal state
    local labels = {

    }

    displayBox:clear()
	--displayBox:append(spc)

 	displayBox:append("Roll 1: "..roll1.."   ")
	if windower.ffxi.get_player().main_job == 17 and settings.Roll_ind_1 ~= settings.Roll_ind_2 then
		displayBox:append("Roll 2: "..roll2.."   ")
	end
	displayBox:append("Autoroll: ")
	if autoroll == true then
		if haveBuff('Invisible') then
			displayBox:append("Suspended: Invisible")
		elseif haveBuff('Sneak') then
			displayBox:append("Suspended: Sneak")
		else
			displayBox:append("On")
		end
	else
		displayBox:append("Off")
	end

	if settings.engaged then
		displayBox:append("  Engaged")
	end
    -- Update and display current info
    displayBox:update(info)
    displayBox:show()

end

windower.register_event('outgoing chunk', function(id, data)
    if id == 0x00D and displayBox then
        displayBox:hide()
    end
end)

windower.register_event('incoming chunk', function(id, data)
    if id == 0x00A and displayBox then
        displayBox:show()
    end
end)
--]]
function parse_rolls(packet_data)--returns roll_name, roll_value(when a roll is rolled or double-upped)
	local r_name;
	local r_value;
	local my_player_id 		= AshitaCore:GetDataManager():GetParty():GetMemberServerId(0);
	local act           = { };
	act.actor_id        = ashita.bits.unpack_be( packet_data, 40, 32 );
	act.target_count    = ashita.bits.unpack_be( packet_data, 72, 8 );
	act.category        = ashita.bits.unpack_be( packet_data, 82, 4 );

	act.param           = ashita.bits.unpack_be( packet_data, 86, 10 );                   --will be the spell a mob is casting, if actor_id is not the player_id etc.. this is not the spellId for when a player is casting
	act.recast          = ashita.bits.unpack_be( packet_data, 118, 10 );                  --this will have a value when the player resolves a spell, not sure about others
	act.unknown         = 0;
	act.targets         = { };
	act.name = ''
	
roll_ja_enums =
{
    ["Fighter's Roll"]=98,
    ["Monk's Roll"]=99,
    ["Healer's Roll"]=100,
    ["Wizard's Roll"]=101,
    ["Warlock's Roll"]=102,
    ["Rogue's Roll"]=103,
    ["Gallant's Roll"]=104,
    ["Chaos Roll"]=105,
    ["Beast Roll"]=106,
    ["Choral Roll"]=107,
    ["Hunter's Roll"]=108,
    ["Samurai Roll"]=109,
    ["Ninja Roll"]=110,
    ["Drachen Roll"]=111,
    ["Evoker's Roll"]=112,
    ["Magus's Roll"]=113,
    ["Corsair's Roll"]=114,
    ["Puppet Roll"]= 115,
    ["Dancer's Roll"]=116,
    ["Scholar's Roll"]=117,
    ["Bolter's Roll"]=118,
    ["Caster's Roll"]= 119,
    ["Courser's Roll"]=120,
    ["Blitzer's Roll"]=121,
    ["Tactician's Roll"]=122,
    ["Allies' Roll"]=302,
    ["Miser's Roll"]=303,
    ["Companion's Roll"]=304,
    ["Avenger's Roll"]=305,
    ["Naturalist's Roll"]=390,
    ["Runeist's Roll"]=391,
}
	
	local bit           = 150;
	for i = 1, act.target_count do
		act.targets[i]              = { };
		act.targets[i].id           = ashita.bits.unpack_be( packet_data, bit, 32 );
		act.targets[i].action_count = ashita.bits.unpack_be( packet_data, bit + 32, 4 );
		act.targets[i].actions      = { };
		for j = 1, act.targets[i].action_count do-- Loop and fill action data..
			act.targets[i].actions[j]           = { };
			act.targets[i].actions[j].reaction  = ashita.bits.unpack_be( packet_data, bit + 36, 5 );
			act.targets[i].actions[j].animation = ashita.bits.unpack_be( packet_data, bit + 41, 11 );
			act.targets[i].actions[j].effect    = ashita.bits.unpack_be( packet_data, bit + 53, 2 );
			act.targets[i].actions[j].stagger   = ashita.bits.unpack_be( packet_data, bit + 55, 7 );
			act.targets[i].actions[j].param     = ashita.bits.unpack_be( packet_data, bit + 63, 17 );
			act.targets[i].actions[j].message   = ashita.bits.unpack_be( packet_data, bit + 80, 10 );
			act.targets[i].actions[j].unknown   = ashita.bits.unpack_be( packet_data, bit + 90, 31 );
			if (act.category == 6) and (act.actor_id  == my_player_id) and (my_player_id == act.targets[i].id) then
				for k,v in pairs(roll_ja_enums) do
					if (act.param == v) then
						DebugMessage("Found a roll")
						r_name = k;
						r_value = act.targets[i].actions[j].param;
						act.name = r_name
--						if (r_name == nil) then
--							return false
--						else
--							
--						end
					end
				end
--				return false;
			end
			if (ashita.bits.unpack_be( packet_data, bit + 121, 1 ) == 1) then -- Does this action have additional effects.. which include skillchains
				act.targets[i].actions[j].has_add_effect        = true;
				act.targets[i].actions[j].add_effect_animation  = ashita.bits.unpack_be( packet_data, bit + 122, 10 );
				act.targets[i].actions[j].add_effect_effect     = 0; -- Unknown currently..
				act.targets[i].actions[j].add_effect_param      = ashita.bits.unpack_be( packet_data, bit + 132, 17 ); --skillchain dmg
				act.targets[i].actions[j].add_effect_message    = ashita.bits.unpack_be( packet_data, bit + 149, 10 ); --120-132=skillchains, 133 = cosmic elucidation
				bit = bit + 37;
			else
				act.targets[i].actions[j].has_add_effect        = false;
				act.targets[i].actions[j].add_effect_animation  = 0;
				act.targets[i].actions[j].add_effect_effect     = 0;
				act.targets[i].actions[j].add_effect_param      = 0;
				act.targets[i].actions[j].add_effect_message    = 0;
			end
			if (ashita.bits.unpack_be( packet_data, bit + 122, 1 ) == 1) then-- Does this action have spike effects..
				act.targets[i].actions[j].has_spike_effect          = true;
				act.targets[i].actions[j].spike_effect_animation    = ashita.bits.unpack_be( packet_data, bit + 123, 10 );
				act.targets[i].actions[j].spike_effect_effect       = 0; -- Unknown currently..
				act.targets[i].actions[j].spike_effect_param        = ashita.bits.unpack_be( packet_data, bit + 133, 14 );
				act.targets[i].actions[j].spike_effect_message      = ashita.bits.unpack_be( packet_data, bit + 147, 10 );
				bit = bit + 34;
			else
				act.targets[i].actions[j].has_spike_effect          = false;
				act.targets[i].actions[j].spike_effect_animation    = 0;
				act.targets[i].actions[j].spike_effect_effect       = 0;
				act.targets[i].actions[j].spike_effect_param        = 0;
				act.targets[i].actions[j].spike_effect_message      = 0;
			end
			bit = bit + 87;
		end
		bit = bit + 36;
	end
	
	return act
end