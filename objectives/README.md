# Objectives

## WARNING: This addon may cause suspension / ban  
The risk level is probably pretty low. There is a similar windower addon that has been out for a copule of years and there have not been reports of suspension or bans. However, this addon injects packets and could be detected if SE wanted to.

Objectives adds / removes RoE Objectives based on hex id  

It also has a feature to write to file the hex + description of manually added objectives  
File is stored in Ashita base + /roelogs  

/addon load objectives  

/objectives get id  - Gets RoE objective with id format: 0x0ABC  
/objectives remove id - Removes RoE objective with id format: 0x0ABC  
/objectives debug  - Toggles Debug flag on or off  
/objectives write  - Toggles writing RoE Hex + Description to Ashita folder/roelogs  
With write enabled, hex id + description will be written to file when accepting a new RoE objective  
  
/objectives load - Loads list of objective profiles from objprofiles.json  
/objectives save - Saves objective profiles to objprofiles.json  
/objectives list - Lists profiles in objprofiles.json  
/objectives newprofile <profileName> - Adds current RoE Objectives as new profile  
/objectives getwithprofile <profileName> - Gets RoEs in the specified profile  
/objectives removewithprofile <profileName> - Removes RoEs in the specified profile  
/objectives clear - Clears zero progress currently loaded objectives (must zone or add/remove an objective to initilize list  
/objectives clearall - Clears ALL currently loaded objectives regard (must zone or add/remove an objective to initilize list  
/objectives copycat - Enables Copycat mode. Manually getting / removing ROE on main character will use /ms sendTo to update other characters - Edit partylist at top of addon file  
