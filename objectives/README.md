# Objectives

## WARNING: This addon may cause suspension / ban  

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
/objectives loadprofile <profileName>- Loads objectives from profile to add or remove objectives  
/objectives clear - Clears all currently loaded objectives (must zone or add/remove an objective to initilize list  


Spreadsheet with hexID of currently obtained objectives located here:

https://docs.google.com/spreadsheets/d/1OD-BIfd6u35m00Jx-B3jyDwPT_3fp1R0T5_C6xuvMAw/edit?usp=sharing