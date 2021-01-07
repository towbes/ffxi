# AutoFollow

Automove is a library written by https://github.com/Shinzaku/FFXI-Ashita-Addons that has all the memory components needed for overwriting x,y coordinates in memory.  This is not meant to be used on it's own.  The functions can be used inside of another addon (AutoMove)


# Automove

Automove is the addon component written by Shinzaru (with some edits by Towbes) that allows users to record x,y coordinates into a JSON file, then load and follow those coordinates.

Commands:

1. /ap record
Start recording a route, this will record to a JSON file the x,y coords as your character walks until you type /ap record again

2. /ap set
Sets the name of the filename to record to

3. /ap load <filename>
Loads the json file with x,y coordinates (do not include .json in the command)

4. /ap run
Runs the route loaded in the JSON file
