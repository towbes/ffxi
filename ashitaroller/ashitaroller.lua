--v0.3 changes Copyright (c) 2022, Lumlum
--Copyright (c) 2016, Selindrile
--All rights reserved.

--Redistribution and use in source and binary forms, with or without
--modification, are permitted provided that the following conditions are met:

--    * Redistributions of source code must retain the above copyright
--      notice, this list of conditions and the following disclaimer.
--    * Redistributions in binary form must reproduce the above copyright
--      notice, this list of conditions and the following disclaimer in the
--      documentation and/or other materials provided with the distribution.
--    * Neither the name of RollTracker/AshitaRoller nor the
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
_addon.version = '0.3'
_addon.author = 'Selindrile, thanks to: Balloon and Lorand - Ashita port by towbes, matix - v0.3 changes by Lumlum'

require 'common'
require 'ffxi.recast'

rollDelay        = 4 -- The delay to prevent spamming rolls.
rollTimer        = 0;    -- The current time used for delaying packets.
defaults = {}
defaults.Roll1 = 114
defaults.Roll2 = 109
defaults.showdisplay = true
defaults.displayx = nil
defaults.displayy = nil
defaults.engaged = false
defaults.crooked2 = true
defaults.randomdeal = true
defaults.oldrandomdeal = false
defaults.partyalert = false
defaults.gamble = false
zonedelay = 6
stealthy = false
was_stealthy = ''
once = false

zoning_bool = false
lastRoll = 0
rollCrooked = false
rollerTimeout = 0 -- Used to timeout if we haven't rolled in a while

haveRoll1 = false
haveRoll2 = false
haveBust = false
canDouble = false

snakeRecast = nil
foldRecast = nil
phantomRecast = nil
randomDealRecast = nil
doubleupRecast = nil
crookedcardsRecast = nil
roll1RollTime = 0
roll2RollTime = 0

playerid = nil
player = nil
mainjob = nil
mainjob_level = nil
subjob = nil

nextAction = "idle"
nextRoll = 0

DebugMode = false

settings = {}

--GUI Variable
local variables =
{
  ['var_ShowTestWindow_rollsFixedoverlay']             = { 1, ImGuiVar_BOOLCPP }
}

function DebugMessage(message)
  if DebugMode then
    print("\31\200[\31\05RollerDebug\31\200]\31\207 " .. message)
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
function load_config()
  local playername = GetPlayerEntity().Name
  local tempSettings = ashita.settings.load(_addon.path .. '/settings/' .. playername .. '.json');
  if tempSettings ~= nil then
    RollerMessage('Config file found.');
    return tempSettings		
  else
    RollerMessage('Settings profiles could not be loaded. Creating empty settings.');
    tempSettings = defaults;
    return tempSettings
  end
end;

---------------------------------------------------------------------------------------------------
-- func: save_objectives
-- desc: saves current RoE objectives to a file
---------------------------------------------------------------------------------------------------
function save_config()
  local playername = GetPlayerEntity().Name
  DebugMessage("Saved settings/" .. playername .. ".json");
  -- Save the addon settings to a file (from the addonSettings table)
  ashita.settings.save(_addon.path .. '/settings/' .. playername .. '.json', settings);
end;

function doNextAction()
  if nextAction == "idle" then
    return
  elseif nextAction == "snakeeye" then
    if haveBuff('snake eye') then
      nextAction = "doubleup"
    else
      AshitaCore:GetChatManager():QueueCommand('/ja "Snake Eye" <me>', 1)
    end
  elseif nextAction == "doubleup" then
    AshitaCore:GetChatManager():QueueCommand('/ja "Double-Up" <me>', 1)
  elseif nextAction == "crooked" then
    if haveBuff('crooked cards') then
      nextAction = "rolling"
    else
      AshitaCore:GetChatManager():QueueCommand('/ja "Crooked Cards" <me>', 1)
    end
  elseif nextAction == "rolling" then
    if settings.partyalert and rollerTimeout < 2 then
      return
    else
      AshitaCore:GetChatManager():QueueCommand('/ja "'..rollInfo[nextRoll].name..'" <me>', 1)
    end
  elseif nextAction == "randomdeal" then
    if randomDealRecast > 0 then
      nextAction = "idle"
    else
      AshitaCore:GetChatManager():QueueCommand('/ja "Random Deal" <me>', 1)
    end
  elseif nextAction == "fold" then
    if not haveBust then
      nextAction = "idle"
    else
      AshitaCore:GetChatManager():QueueCommand('/ja "Fold" <me>', 1)
    end
  end
end

ashita.register_event('load', function()
    settings = load_config()

    autoroll = false

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
      [71] = {id=71,en="Sneak",ja="スニーク",enl="Sneak",jal="スニーク"},
      [69] = {id=69,en="Invisible",ja="インビジ",enl="Invisible",jal="インビジ"},
      [16] = {id=16,en="amnesia",ja="アムネジア",enl="amnesic",jal="アムネジア"},
      [261] = {id=261,en="impairment",ja="インペア",enl="impaired",jal="インペア"},
      [357] = {id=357,en="Snake Eye",ja="スネークアイ",enl="Snake Eye",jal="スネークアイ"},
      [601] = {id=601,en="Crooked Cards",ja="クルケッドカード",enl="Crooked Cards",jal="クルケッドカード"},
      }, {"id", "en", "ja", "enl", "jal"}

    --GUI stuff
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
-- func: ShowExampleAppFixedOverlay
-- desc: Shows the example fixed overlay.
----------------------------------------------------------------------------------------------------
function rollsFixedOverlay()

  -- Display the pet information..
  if settings.showdisplay then
    imgui.SetNextWindowSize(220, 200, ImGuiSetCond_Always);
    if (imgui.Begin('AshitaRoller') == false) then
      imgui.End();
      return;
    end

    imgui.Text('Roll1: ' .. rollInfo[settings.Roll1].name);
    imgui.Text('Roll2: ' .. rollInfo[settings.Roll2].name);
    imgui.Text('Autoroll: ' .. tostring(autoroll));
    if (settings.engaged) then
      imgui.Text("Engaged only mode on")
    end
    if(settings.crooked2) then
      imgui.Text("Crooked on roll 2 : ON")
    else
      imgui.Text("Crooked on roll 2 : OFF")
    end
    if(settings.randomdeal) then
      imgui.Text("Random Deal : ON")
    else
      imgui.Text("Random Deal : OFF")
    end
    if(settings.oldrandomdeal) then
      imgui.Text("Random Deal Mode : Fold/Snake")
    else
      imgui.Text("Random Deal Mode : Crooked")
    end
    if(settings.gamble) then
      imgui.Text("Gamble : ON")
    else
      imgui.Text("Gamble : OFF")
    end
    if(settings.partyalert) then
      imgui.Text("Party Alert : ON")
    else
      imgui.Text("Party Alert : OFF")
    end
    if (stealthy) then
      imgui.Text("Invis/Sneak - No rolling");
    end

    imgui.End();
  end
end

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


    if cmd[1] == nil or cmd[1] == "rolls" then

      if autoroll == true then
        RollerMessage('Automatic Rolling is ON.')
      else
        RollerMessage('Automatic Rolling is OFF.')
      end
      roll1 = 304
      roll2 = 106
      RollerMessage('Roll 1: '..rollInfo[settings.Roll1].name)
      RollerMessage('Roll 2: '..rollInfo[settings.Roll2].name)
      return true
    else
      if cmd[1] == "help" then
        -- Prints the addon help..
        print_help('/roller', {
            {'/roller', ' - Shows current rolls'},
            {'roll' ,'To start or stop auto rolling type '},
            {'roll# rollname', 'Set roll to a roll from mapping table(can use beginning of roll name ie: cor = corsair, or stat)'},
            {'preset' , 'Set preset rolls (TP, Acc, WS, Nuke, Pet, PetNuke)'},
            {'engaged' , 'on/off to enable or disable only rolling while engaged'},
            {'crooked2','on/off - Allows Crooked Cards to also be used for the second roll'},
            {'randomdeal','on/off - Allows Random Deal to be used'},
            {'oldrandomdeal','on/off - on;focuses on resetting Snake Eye/Fold, off;focuses on resetting Crooked Cards'},
            {'gamble','on/off - Abuses bust immunity to try to get double 11 as much as possible'},
            {'partyalert','on/off - Writes a message in /party a few seconds before rolling'},
            {'once','Will roll both rolls once then go back to idle'}
          });
      elseif cmd[1] == "debug" then
        if DebugMode == false then
          RollerMessage("Debug mode enabled")
          DebugMode = true
        else
          RollerMessage("Debug mode disabled")
          DebugMode = false
        end
      elseif cmd[1] == "flags" then
        DebugMessage("zoningbool " .. tostring(zoning_bool))
        DebugMessage("lastroll " .. tostring(lastRoll))
        DebugMessage("rollcrooked " .. tostring(rollCrooked))
        DebugMessage("haveroll1 " .. tostring(haveRoll1))
        DebugMessage("haveroll2 " .. tostring(haveRoll2))
        DebugMessage("havebust " .. tostring(haveBust))
        DebugMessage("candouble " .. tostring(canDouble))		
        DebugMessage("crooked2 " .. tostring(settings.crooked2))
        DebugMessage("randomdeal " .. tostring(settings.randomdeal))
        DebugMessage("oldrandomdeal " .. tostring(settings.oldrandomdeal))
        DebugMessage("partyalert " .. tostring(settings.partyalert))	
        DebugMessage("gamble " .. tostring(settings.gamble))	
        DebugMessage("once " .. tostring(once))	
        DebugMessage("nextAction " .. tostring(nextAction))
        if nextRoll ~= 0 then
          DebugMessage("nextRoll " .. tostring(rollInfo[nextRoll].name))
        else
          DebugMessage("nextRoll noRollFound")
        end
      elseif cmd[1] == "display" then
        if cmd[2] == nil then
          settings.showdisplay = not settings.showdisplay
          save_config()
        elseif cmd[2] == 'on' or cmd[2] == 'show' then
          settings.showdisplay = true
          save_config()
          RollerMessage('Display On.')
        elseif cmd[2] == 'off' or cmd[2] == 'hide' then
          settings.showdisplay = false
          save_config()
          RollerMessage('Display Off.')
        else
          RollerMessage('Not a recognized display subcommand. (Show, Hide)')
        end		
      elseif cmd[1] == "engaged" then
        if cmd[2] == nil then
          settings.engaged = not settings.engaged
          save_config()
        elseif cmd[2] == 'on' or cmd[2] == 'true' then
          settings.engaged = true
          save_config()
          RollerMessage('Engaged Only: On.')
        elseif cmd[2] == 'off' or cmd[2] == 'false' then
          settings.engaged = false
          save_config()
          RollerMessage('Engaged Only: Off.')
        else
          RollerMessage('Not a recognized engaged subcommand. (on, off)')
        end
      elseif cmd[1] == "start" or cmd[1] == "go" or cmd[1] == "begin" or cmd[1] == "enable" or cmd[1] == "on" or cmd[1] == "engage" or cmd[1] == "resume" then
        zonedelay = 6
        if autoroll == false then
          autoroll = true
          RollerMessage('Enabling Automatic Rolling.')
        elseif autoroll == true then
          RollerMessage('Automatic Rolling already enabled.')
        end
      elseif cmd[1] == "stop" or cmd[1] == "quit" or cmd[1] == "end" or cmd[1] == "disable" or cmd[1] == "off" or cmd[1] == "disengage" or cmd[1] == "pause" then
        zonedelay = 6
        once = false
        if autoroll == true then
          autoroll = false
          RollerMessage('Disabling Automatic Rolling.')
        elseif autoroll == false then
          RollerMessage('Automatic Rolling already disabled.')
        end
      elseif cmd[1] == "roll" then
        if cmd[2] == "roll1" then
          AshitaCore:GetChatManager():QueueCommand('/ja "'..rollInfo[settings.Roll1].name..'" <me>', 1)
        elseif cmd[2] == "roll2" then
          AshitaCore:GetChatManager():QueueCommand('/ja "'..rollInfo[settings.Roll2].name..'" <me>', 1)
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
        settings.Roll1 = cmd[2]
        RollerMessage('Set Role 1 to ' .. rollInfo[settings.Roll1].name)
      elseif cmd[1] == "setroll2" then
        settings.Roll2 = cmd[2]
        RollerMessage('Set Role 2 to ' .. rollInfo[settings.Roll2].name)
      elseif cmd[1] == "melee" then
        settings.Roll1 = 109 --sam
        settings.Roll2 = 105 -- chaos
        RollerMessage('Setting Roll 1 to: '..rollInfo[settings.Roll1].name)
        RollerMessage('Setting Roll 2 to: '..rollInfo[settings.Roll2].name)
        save_config()

      elseif cmd[1]:startswith('exp') or cmd[1]:startswith('cap') or cmd[1] == "cp" then
        settings.Roll1 = 114
        settings.Roll2 = 116 -- dancer
        rollInfo[settings.Roll1].buffid = rollInfo[settings.Roll1].buffid
        rollInfo[settings.Roll2].buffid = rollInfo[settings.Roll2].buffid
        rollInfo[settings.Roll1].name = rollInfo[settings.Roll1].name
        rollInfo[settings.Roll2].name = rollInfo[settings.Roll2].name
        RollerMessage('Setting Roll 1 to: '..rollInfo[settings.Roll1].name)
        RollerMessage('Setting Roll 2 to: '..rollInfo[settings.Roll2].name)
        save_config()

      elseif cmd[1] == "tp" or cmd[1] == "stp" then
        settings.Roll1 = 109 -- sam
        settings.Roll2 = 98 -- fighter
        RollerMessage('Setting Roll 1 to: '..rollInfo[settings.Roll1].name)
        RollerMessage('Setting Roll 2 to: '..rollInfo[settings.Roll2].name)
        save_config()

      elseif cmd[1] == "speed" or cmd[1] == "movespeed" or cmd[1]:startswith('bolt') then
        settings.Roll1 = 118
        settings.Roll2 = 118
        rollInfo[settings.Roll1].buffid = rollInfo[settings.Roll1].buffid
        rollInfo[settings.Roll2].buffid = rollInfo[settings.Roll2].buffid
        rollInfo[settings.Roll1].name = rollInfo[settings.Roll1].name
        rollInfo[settings.Roll2].name = rollInfo[settings.Roll2].name
        RollerMessage('Setting Roll 1 to: '..rollInfo[settings.Roll1].name)
        RollerMessage('Setting Roll 2 to: '..rollInfo[settings.Roll2].name)
        save_config()

      elseif cmd[1]:startswith('acc') or cmd[1] == "highacc" then
        settings.Roll1 = 109 -- sam
        settings.Roll2 = 108 -- hunter
        RollerMessage('Setting Roll 1 to: '..rollInfo[settings.Roll1].name)
        RollerMessage('Setting Roll 2 to: '..rollInfo[settings.Roll2].name)
        save_config()

      elseif cmd[1] == "ws" or cmd[1] == "wsd" then
        settings.Roll1 = 105 -- chaos
        settings.Roll2 = 98 -- fighter
        RollerMessage('Setting Roll 1 to: '..rollInfo[settings.Roll1].name)
        RollerMessage('Setting Roll 2 to: '..rollInfo[settings.Roll2].name)
        save_config()

      elseif cmd[1] == "nuke" or cmd[1] == "burst" or cmd[1] == "matk" or cmd[1]:startswith('mag')  then
        settings.Roll1 = 101 --wizard
        settings.Roll2 = 102 -- warlock
        RollerMessage('Setting Roll 1 to: '..rollInfo[settings.Roll1].name)
        RollerMessage('Setting Roll 2 to: '..rollInfo[settings.Roll2].name)
        save_config()

      elseif cmd[1] == "pet" or cmd[1]:startswith("petphy") then
        settings.Roll1 = 304
        settings.Roll2 = 106
        RollerMessage('Setting Roll 1 to: '..rollInfo[settings.Roll1].name)
        RollerMessage('Setting Roll 2 to: '..rollInfo[settings.Roll2].name)
        save_config()

      elseif cmd[1] == "petacc" or cmd[1]:startswith("petphy") then
        settings.Roll1 = 304
        settings.Roll2 = 111 -- drachen
        RollerMessage('Setting Roll 1 to: '..rollInfo[settings.Roll1].name)
        RollerMessage('Setting Roll 2 to: '..rollInfo[settings.Roll2].name)
        save_config()

      elseif cmd[1] == "petnuke" or cmd[1]:startswith('petma') then
        settings.Roll1 = 115 --pup
        settings.Roll2 = 304 --companion
        RollerMessage('Setting Roll 1 to: '..rollInfo[settings.Roll1].name)
        RollerMessage('Setting Roll 2 to: '..rollInfo[settings.Roll2].name)
        save_config()

      elseif cmd[1] == "roll1" then
        local rollchange = false
        if cmd[2] == nil then RollerMessage('Roll 1: '..rollInfo[settings.Roll1].name) return
        elseif cmd[2]:startswith("warlock") or cmd[2]:startswith("macc") or cmd[2]:startswith("magic ac") or cmd[2]:startswith("rdm") then settings.Roll1 = 102 save_config() rollchange = true
        elseif cmd[2]:startswith("fight") or cmd[2]:startswith("double") or cmd[2]:startswith("dbl") or cmd[2]:startswith("war") then settings.Roll1 = 98 save_config() rollchange = true
        elseif cmd[2]:startswith("monk") or cmd[2]:startswith("subtle") or cmd[2]:startswith("mnk") then settings.Roll1 = 99 save_config() rollchange = true
        elseif cmd[2]:startswith("heal") or cmd[2]:startswith("cure") or cmd[2]:startswith("whm") then settings.Roll1 = 100 save_config() rollchange = true
        elseif cmd[2]:startswith("wizard") or cmd[2]:startswith("matk") or cmd[2]:startswith("magic at") or cmd[2]:startswith("blm") then settings.Roll1 = 101 save_config() rollchange = true
        elseif cmd[2]:startswith("rogue") or cmd[2]:startswith("crit") or cmd[2]:startswith("thf") then settings.Roll1 = 103 save_config() rollchange = true
        elseif cmd[2]:startswith("gallant") or cmd[2]:startswith("def") or cmd[2]:startswith("pld") then settings.Roll1 = 104 save_config() rollchange = true
        elseif cmd[2]:startswith("chaos") or cmd[2]:startswith("attack") or cmd[2]:startswith("atk") or cmd[2]:startswith("drk") then settings.Roll1 = 105 save_config() rollchange = true
        elseif cmd[2]:startswith("beast") or cmd[2]:startswith("pet at") or cmd[2]:startswith("bst") then settings.Roll1 = 106 save_config() rollchange = true
        elseif cmd[2]:startswith("choral") or cmd[2]:startswith("inter") or cmd[2]:startswith("spell inter") or cmd[2]:startswith("brd") then settings.Roll1 = 107 save_config() rollchange = true
        elseif cmd[2]:startswith("hunt") or cmd[2]:startswith("acc") or  cmd[2]:startswith("rng") then settings.Roll1 = 108 save_config() rollchange = true
        elseif cmd[2]:startswith("sam") or cmd[2]:startswith("stp") or cmd[2]:startswith("store") then settings.Roll1 = 109 save_config() rollchange = true
        elseif cmd[2]:startswith("nin") or cmd[2]:startswith("eva") then settings.Roll1 = 110 save_config() rollchange = true
        elseif cmd[2]:startswith("drach") or cmd[2]:startswith("pet ac") or cmd[2]:startswith("drg") then settings.Roll1 = 111 save_config() rollchange = true
        elseif cmd[2]:startswith("evoke") or cmd[2]:startswith("refresh") or cmd[2]:startswith("smn") then settings.Roll1 = 112 save_config() rollchange = true
        elseif cmd[2]:startswith("magus") or cmd[2]:startswith("mdb") or cmd[2]:startswith("magic d") or cmd[2]:startswith("blu") then settings.Roll1 = 113 save_config() rollchange = true
        elseif cmd[2]:startswith("cor") or cmd[2]:startswith("exp") then settings.Roll1 = 114 save_config() rollchange = true
        elseif cmd[2]:startswith("pup") or cmd[2]:startswith("pet m") then settings.Roll1 = 115 save_config() rollchange = true
        elseif cmd[2]:startswith("dance") or cmd[2]:startswith("regen") or cmd[2]:startswith("dnc") then settings.Roll1 = 116 save_config() rollchange = true
        elseif cmd[2]:startswith("sch") or cmd[2]:startswith("conserve m") then settings.Roll1 = 117 save_config() rollchange = true
        elseif cmd[2]:startswith("bolt") or cmd[2]:startswith("move") or cmd[2]:startswith("flee") or cmd[2]:startswith("speed") then settings.Roll1 = 118 save_config() rollchange = true
        elseif cmd[2]:startswith("cast") or cmd[2]:startswith("fast") or cmd[2]:startswith("fc") then settings.Roll1 = 119 save_config() rollchange = true
        elseif cmd[2]:startswith("course") or cmd[2]:startswith("snap") then settings.Roll1 = 120 save_config() rollchange = true
        elseif cmd[2]:startswith("blitz") or cmd[2]:startswith("delay") then settings.Roll1 = 121 save_config() rollchange = true
        elseif cmd[2]:startswith("tact") or cmd[2]:startswith("regain") then settings.Roll1 = 122 save_config() rollchange = true
        elseif cmd[2]:startswith("all") or cmd[2]:startswith("skillchain") then settings.Roll1 = 302 save_config() rollchange = true
        elseif cmd[2]:startswith("miser") or cmd[2]:startswith("save tp") or cmd[2]:startswith("conserve t") then settings.Roll1 = 303 save_config() rollchange = true
        elseif cmd[2]:startswith("companion") or cmd[2]:startswith("pet r") then settings.Roll1 = 304 save_config() rollchange = true
        elseif cmd[2]:startswith("avenge") or cmd[2]:startswith("counter") then settings.Roll1 = 305 save_config() rollchange = true
        elseif cmd[2]:startswith("natural") or cmd[2]:startswith("enhance") or cmd[2]:startswith("duration") then settings.Roll1 = 390 save_config() rollchange = true
        elseif cmd[2]:startswith("run") or cmd[2]:startswith("meva") or cmd[2]:startswith("magic e") then settings.Roll1 = 391 save_config() rollchange = true
        end

        if rollchange == true then
          RollerMessage('Setting Roll 1 to: '..rollInfo[settings.Roll1].name..'')
        else
          RollerMessage('Invalid roll name, Roll 1 remains: '..rollInfo[settings.Roll1].name..'')
        end

      elseif cmd[1] == "roll2" then
        local rollchange = false
        if cmd[2] == nil then RollerMessage('Roll 1: '..rollInfo[settings.Roll2].name) return
        elseif cmd[2]:startswith("warlock") or cmd[2]:startswith("macc") or cmd[2]:startswith("magic ac") or cmd[2]:startswith("rdm") then settings.Roll2 = 102 save_config() rollchange = true
        elseif cmd[2]:startswith("fight") or cmd[2]:startswith("double") or cmd[2]:startswith("dbl") or cmd[2]:startswith("war") then settings.Roll2 = 98 save_config() rollchange = true
        elseif cmd[2]:startswith("monk") or cmd[2]:startswith("subtle") or cmd[2]:startswith("mnk") then settings.Roll2 = 99 save_config() rollchange = true
        elseif cmd[2]:startswith("heal") or cmd[2]:startswith("cure") or cmd[2]:startswith("whm") then settings.Roll2 = 100 save_config() rollchange = true
        elseif cmd[2]:startswith("wizard") or cmd[2]:startswith("matk") or cmd[2]:startswith("magic at") or cmd[2]:startswith("blm") then settings.Roll2 = 101 save_config() rollchange = true
        elseif cmd[2]:startswith("rogue") or cmd[2]:startswith("crit") or cmd[2]:startswith("thf") then settings.Roll2 = 103 save_config() rollchange = true
        elseif cmd[2]:startswith("gallant") or cmd[2]:startswith("def") or cmd[2]:startswith("pld") then settings.Roll2 = 104 save_config() rollchange = true
        elseif cmd[2]:startswith("chaos") or cmd[2]:startswith("attack") or cmd[2]:startswith("atk") or cmd[2]:startswith("drk") then settings.Roll2 = 105 save_config() rollchange = true
        elseif cmd[2]:startswith("beast") or cmd[2]:startswith("pet at") or cmd[2]:startswith("bst") then settings.Roll2 = 106 save_config() rollchange = true
        elseif cmd[2]:startswith("choral") or cmd[2]:startswith("inter") or cmd[2]:startswith("spell inter") or cmd[2]:startswith("brd") then settings.Roll2 = 107 save_config() rollchange = true
        elseif cmd[2]:startswith("hunt") or cmd[2]:startswith("acc") or  cmd[2]:startswith("rng") then settings.Roll2 = 108 save_config() rollchange = true
        elseif cmd[2]:startswith("sam") or cmd[2]:startswith("stp") or cmd[2]:startswith("store") then settings.Roll2 = 109 save_config() rollchange = true
        elseif cmd[2]:startswith("nin") or cmd[2]:startswith("eva") then settings.Roll2 = 110 save_config() rollchange = true
        elseif cmd[2]:startswith("drach") or cmd[2]:startswith("pet ac") or cmd[2]:startswith("drg") then settings.Roll2 = 111 save_config() rollchange = true
        elseif cmd[2]:startswith("evoke") or cmd[2]:startswith("refresh") or cmd[2]:startswith("smn") then settings.Roll2 = 112 save_config() rollchange = true
        elseif cmd[2]:startswith("magus") or cmd[2]:startswith("mdb") or cmd[2]:startswith("magic d") or cmd[2]:startswith("blu") then settings.Roll2 = 113 save_config() rollchange = true
        elseif cmd[2]:startswith("cor") or cmd[2]:startswith("exp") then settings.Roll2 = 114 save_config() rollchange = true
        elseif cmd[2]:startswith("pup") or cmd[2]:startswith("pet m") then settings.Roll2 = 115 save_config() rollchange = true
        elseif cmd[2]:startswith("dance") or cmd[2]:startswith("regen") or cmd[2]:startswith("dnc") then settings.Roll2 = 116 save_config() rollchange = true
        elseif cmd[2]:startswith("sch") or cmd[2]:startswith("conserve m") then settings.Roll2 = 117 save_config() rollchange = true
        elseif cmd[2]:startswith("bolt") or cmd[2]:startswith("move") or cmd[2]:startswith("flee") or cmd[2]:startswith("speed") then settings.Roll2 = 118 save_config() rollchange = true
        elseif cmd[2]:startswith("cast") or cmd[2]:startswith("fast") or cmd[2]:startswith("fc") then settings.Roll2 = 119 save_config() rollchange = true
        elseif cmd[2]:startswith("course") or cmd[2]:startswith("snap") then settings.Roll2 = 120 save_config() rollchange = true
        elseif cmd[2]:startswith("blitz") or cmd[2]:startswith("delay") then settings.Roll2 = 121 save_config() rollchange = true
        elseif cmd[2]:startswith("tact") or cmd[2]:startswith("regain") then settings.Roll2 = 122 save_config() rollchange = true
        elseif cmd[2]:startswith("all") or cmd[2]:startswith("skillchain") then settings.Roll2 = 302 save_config() rollchange = true
        elseif cmd[2]:startswith("miser") or cmd[2]:startswith("save tp") or cmd[2]:startswith("conserve t") then settings.Roll2 = 303 save_config() rollchange = true
        elseif cmd[2]:startswith("companion") or cmd[2]:startswith("pet r") then settings.Roll2 = 304 save_config() rollchange = true
        elseif cmd[2]:startswith("avenge") or cmd[2]:startswith("counter") then settings.Roll2 = 305 save_config() rollchange = true
        elseif cmd[2]:startswith("natural") or cmd[2]:startswith("enhance") or cmd[2]:startswith("duration") then settings.Roll2 = 390 save_config() rollchange = true
        elseif cmd[2]:startswith("run") or cmd[2]:startswith("meva") or cmd[2]:startswith("magic e") then settings.Roll2 = 391 save_config() rollchange = true
        end

        if rollchange == true then
          RollerMessage('Setting Roll 2 to: '..rollInfo[settings.Roll2].name)
        else
          RollerMessage('Invalid roll name, Roll 2 remains: '..rollInfo[settings.Roll2].name)
        end
      elseif cmd[1]=="crooked2" then
        if cmd[2]=="on" then
          RollerMessage('Crooked Cards will also be used for roll 2.')
          settings.crooked2 = true
        elseif cmd[2]=="off" then
          RollerMessage('Crooked Cards will only be used for roll 1.')
          settings.crooked2 = false
        end
        save_config()
      elseif cmd[1]=="randomdeal" then
        if cmd[2]=="on" then
          RollerMessage('Random Deal will be used when needed.')
          settings.randomdeal = true
        elseif cmd[2]=="off" then
          RollerMessage('Random Deal will never be used.')
          settings.randomdeal = false
        end
        save_config()
      elseif cmd[1]=="oldrandomdeal" then
        if cmd[2]=="on" then
          RollerMessage('Random Deal will be used for Fold/Snake Eye.')
          settings.oldrandomdeal = true
        elseif cmd[2]=="off" then
          RollerMessage('Random Deal will be used for Crooked Cards.')
          settings.oldrandomdeal = false
        end
        save_config()
      elseif cmd[1]=="partyalert" then
        if cmd[2]=="on" then
          RollerMessage('Will do a party alert to inform players when you are about to roll.')
          settings.partyalert = true
        elseif cmd[2]=="off" then
          RollerMessage('Will not do a party alert to inform players when you are about to roll.')
          settings.partyalert = false
        end
        save_config()
      elseif cmd[1]=="gamble" then
        if cmd[2]=="on" then
          RollerMessage('If immune to bust, it will keep gambling until it gets a second 11.')
          settings.gamble = true
        elseif cmd[2]=="off" then
          RollerMessage('Even if immune to bust, it will try to get rolls up quickly')
          settings.gamble = false
        end
        save_config()
      elseif cmd[1]=="once" then
        RollerMessage('Will roll until both rolls are up.')
        once = true
      end
    end
    return true;

  end);


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
        if rollID == 177 then return false end

        if act.actor_id == playerid then
          rollerTimeout = 0 -- We rolled so set the timeout to 0
          local rollname = act.name
          DebugMessage("Rollname: " .. rollname)
          local rollNum = act.targets[1].actions[1].param
          DebugMessage("RollNum: " .. rollNum)
          DebugMessage("RollId: " .. rollID)
          --We need to force haveRoll update for snake eye use, normal update mode doesn't work here
          if rollID == settings.Roll1 then
            haveRoll1 = true
          elseif rollID == settings.Roll2 then
            haveRoll2 = true
          end          
          -- We busted so resetting to roll again
          if rollNum > 11 then
            DebugMessage("Busted...")
            nextAction = "idle"
            return false
            --If roll is lucky or 11 returns.
          elseif (rollNum == rollInfo[rollID].stats[14] and (not settings.gamble or (not lastRoll == 11 and foldRecast > 0) or rollCrooked)) or rollNum == 11 then
            DebugMessage("Lucky or 11, done!")
            nextAction = "idle"
            RollerMessage(rollname .. " final roll: " .. rollNum)
            lastRoll = rollNum
            return false
          end

          if (not autoroll and not once) or haveBuff('amnesia') or haveBuff('impairment') then return false end

          if mainjob == 17 then
            if settings.gamble and lastRoll == 11 then
              if snakeRecast == 0 and (rollNum == 10 or (rollNum == (rollInfo[rollID].stats[14]-1) and rollCrooked)) then
                DebugMessage("Using Snake Eye for 11 or crooked lucky ")
                nextAction = "snakeeye";
              else
                DebugMessage("Rolling because we're immune to bust and gambling")
                nextAction = "doubleup"
              end
            else
              if snakeRecast == 0 and (rollNum == 10 or (rollNum == (rollInfo[rollID].stats[14]-1) and (not settings.gamble or rollCrooked))) then
                DebugMessage("Using Snake Eye for lucky or 11, will only go for 11 if gamble mode is on, unless crooked")
                nextAction = "snakeeye"
              elseif snakeRecast == 0 and (foldRecast > 0 or (rollCrooked and not settings.gamble)) and rollNum == rollInfo[rollID].stats[15] then
                DebugMessage("Using Snake Eye to remove unlucky if fold is down or if this is a crooked roll")
                nextAction = "snakeeye"
              elseif foldRecast == 0 and (not rollCrooked or settings.gamble) then
                DebugMessage("Trying our luck because roll is not crooked and we have fold up, will ignore crooked if gamble mode is on")
                nextAction = "doubleup"
              elseif lastRoll == 11 and not rollCrooked then
                DebugMessage("Immune to bust;Trying to get an 11 if roll isn't crooked")
                nextAction = "doubleup"
              elseif rollNum < 6 then
                DebugMessage("Rolling because roll is smaller than 6")
                nextAction = "doubleup"
              elseif haveRoll1 and haveRoll2 and snakeRecast == 0 and rollNum+1 ~= rollInfo[rollID].stats[15] and os.time()-roll1RollTime<240 and os.time()-roll2RollTime<240 then
                DebugMessage("Trying our luck with Snake Eye because this is the last roll and rollnumber+1 is not unlucky, Snake Eye will be back for next roll")
                nextAction = "snakeeye"
              else
                DebugMessage("Finished this roll")
                nextAction = "idle"
                RollerMessage(rollname .. " final roll: " .. rollNum)
                lastRoll = rollNum
              end
            end
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

function doRoll()
  doNextAction()
  --Not sure this is needed, might remove
  updateRecast()
  --Timeout after 40 secs without rolling, should not be needed but might be useful if something goes unexpected
  if  (os.time() >= (rollTimer + rollDelay)) then
    rollTimer = os.time();
    rollerTimeout = rollerTimeout + 1
    if rollerTimeout > 11 then
      nextAction = "idle"
    end

    --No need to do something if we can't do it
    if haveBuff('amnesia') or haveBuff('impairment') then 
      return
    end

    updateRolls()

    --No need to do something if we don't want to roll or if we are already doing something
    if (not autoroll and not once) or nextAction ~= "idle" then
      return
    end
    --No need to do something if we already got both rolls
    if haveRoll1 and haveRoll2 and nextAction=="idle" then
      if once then
        DebugMessage("Rolled once, rolls are up")
      end
      once = false
      return
    end
    --Nothing done while sneak or invisible
    if haveBuff('Sneak') or haveBuff('Invisible') then
      DebugMessage("Stealthy activated")
      stealthy = true
    else
      stealthy = false
    end
    if stealthy then return end
    --Nothing done if we are not COR or /COR
    if not (mainjob == 17 or subjob == 17) then return end
    --Rolls only while engaged if turned on
    status = player.Status
    if not (((status == 0) and not settings.engaged) or status == 1) then return end

    --NEW RANDOM DEAL - Crooked Cards
    if mainjob == 17 and phantomRecast == 0 and crookedcardsRecast > 0 and randomDealRecast == 0 and settings.randomdeal and not settings.oldrandomdeal then
      DebugMessage("Using Random Deal to reset Crooked Cards")
      nextAction = "randomdeal"
      return  
      --OLD BEHAVIOR - Fold or Snake Eye
    elseif mainjob == 17 and phantomRecast == 0 and (foldRecast > 0 or snakeRecast > 0) and randomDealRecast == 0 and settings.randomdeal and settings.oldrandomdeal then
      DebugMessage("Using Random Deal to reset Fold or Snake Eye")
      nextAction = "randomdeal"
      return  
    end

    if mainjob == 17 and haveBust and foldRecast == 0 then 
      DebugMessage("We busted, folding")
      nextAction = "fold"
      return
    end

    if not haveRoll1 and not haveRoll2 and phantomRecast == 0 then
      DebugMessage("We don't have any rolls")
      lastRoll = 0
    end

    if not haveRoll1 and phantomRecast == 0 then
      DebugMessage("We don't have roll 1 buff, trying roll1")
      roll1RollTime = os.time();
      if settings.partyalert then
        AshitaCore:GetChatManager():QueueCommand('/p Rolling '..rollInfo[settings.Roll1].name..' in 8 secs, stay close <call12>', 1);
      end
      rollCrooked = false
      rollerTimeout = 0
      if mainjob == 17 and mainjob_level > 94 and crookedcardsRecast == 0 then 
        DebugMessage("Using Crooked Cards")
        RollerMessage(rollInfo[settings.Roll1].name .. " Lucky: " .. rollInfo[settings.Roll1].stats[14] .. " Unlucky: " .. rollInfo[settings.Roll1].stats[15])
        rollCrooked = true
        nextRoll = settings.Roll1
        nextAction = "crooked"
      else
        RollerMessage(rollInfo[settings.Roll1].name .. " Lucky: " .. rollInfo[settings.Roll1].stats[14] .. " Unlucky: " .. rollInfo[settings.Roll1].stats[15])
        nextRoll = settings.Roll1
        nextAction = "rolling"
      end
    elseif not haveRoll2 and not haveBust and phantomRecast == 0 then
      DebugMessage("We don't have roll 2 buff, trying roll2")
      roll2RollTime = os.time();
      if settings.partyalert then
        AshitaCore:GetChatManager():QueueCommand('/p Rolling '..rollInfo[settings.Roll2].name..' in 8 secs, stay close <call12>', 1);
      end
      rollCrooked = false
      rollerTimeout = 0
      if mainjob == 17 and mainjob_level > 94 and crookedcardsRecast == 0 and settings.crooked2 then 
        DebugMessage("Using Crooked Cards")
        RollerMessage(rollInfo[settings.Roll2].name .. " Lucky: " .. rollInfo[settings.Roll2].stats[14] .. " Unlucky: " .. rollInfo[settings.Roll2].stats[15])
        rollCrooked = true
        nextRoll = settings.Roll2
        nextAction = "crooked"
      else
        RollerMessage(rollInfo[settings.Roll2].name .. " Lucky: " .. rollInfo[settings.Roll2].stats[14] .. " Unlucky: " .. rollInfo[settings.Roll2].stats[15])
        nextRoll = settings.Roll2
        nextAction = "rolling"
      end
    end
  end
end

function updateRolls()
  haveRoll1 = false
  haveRoll2 = false
  haveBust = false

  --DATA GATHERING
  --Rolls&Bust
  local buffs						= AshitaCore:GetDataManager():GetPlayer():GetBuffs();
  for i,v in pairs(buffs) do
    if buffs[i] == rollInfo[settings.Roll1].buffid then
      haveRoll1 = true
    end
    if buffs[i] == rollInfo[settings.Roll2].buffid then
      haveRoll2 = true
    end	
    if buffs[i] == 309 then
      haveBust = true
    end	
  end
end

function updateRecast()
  --Recasts&Infos
  snakeRecast = ashita.ffxi.recast.get_ability_recast_by_id(197);--JAid 177 , RecastId 197
  foldRecast = ashita.ffxi.recast.get_ability_recast_by_id(198);-- JAid 178, RecastId 198
  phantomRecast = ashita.ffxi.recast.get_ability_recast_by_id(193);-- JAid 97, RecastId 193
  randomDealRecast = ashita.ffxi.recast.get_ability_recast_by_id(196);-- JAid 133, RecastId 196
  doubleupRecast = ashita.ffxi.recast.get_ability_recast_by_id(194);-- JAid 123, RecastId 194
  crookedcardsRecast = ashita.ffxi.recast.get_ability_recast_by_id(96);-- JAid 392, RecastId 96

  player = GetPlayerEntity()
  playerid = AshitaCore:GetDataManager():GetParty():GetMemberServerId(0)
  mainjob = AshitaCore:GetDataManager():GetPlayer():GetMainJob()
  mainjob_level = AshitaCore:GetDataManager():GetPlayer():GetMainJobLevel()
  subjob = AshitaCore:GetDataManager():GetPlayer():GetSubJob()  
end

ashita.register_event('render', function()
    updateRecast()
    if (player == nil) then
      zonedelay = 0
      autoroll = false
      lastRoll = 0
      nextAction = "idle"
      return
    end

    if zoning_bool then
      return
    end

    rollsFixedOverlay()
    doRoll()
  end);

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