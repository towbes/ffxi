# ashitaroller
FFXI Addon for Ashita - Automated COR Rolling

- Original windower addon : https://github.com/Noobcakes/Roller
- Ashita port this is based on : https://github.com/towbes/ffxi/tree/master/ashitaroller

## Features
- Automatic corsair rolling
- Can use Crooked Cards, Fold, Snake Eye and Random Deal
- Crooked Cards can focus on one roll or be used for both, Random Deal can be disabled
- Stops on zones
- Quick mode to put good rolls up decently quick (i.e : Quick ambu runs), Gamble mode to try and maintain double 11's abusing bust immunity (i.e : ML grind)

## Commands
- On/Start/Go/Enable/On/Engage - Start rolling  
- Stop/Off/Quit/End/Disable/Disengage - Stop rolling  
- roll1 <roll> (can use beginning of roll name ie: cor = corsair's, or stat)
- roll2 <roll>
- engaged on/off - Enable or disable only rolling while engaged
- crooked2 on/off - Allows Crooked Cards to also be used for the second roll
- randomdeal on/off - Allows Random Deal to be used
- oldrandomdeal on/off - on;focuses on resetting Snake Eye/Fold, off;focuses on resetting Crooked Cards
- gamble on/off - Abuses bust immunity to try to get double 11's as much as possible
- partyalert on/off - Writes a message in /party a few seconds before rolling
- once - Will roll both rolls once then go back to idle

## Examples
- Quick Ambu runs (Quick mode) : crooked2 on/randomdeal on/oldrandomdeal off/gamble off
- AFK ML party (Gamble mode) : COR(roll1)/SAM(roll2)/crooked2 off/randomdeal on/oldrandomdeal on/gamble on

## v0.3 Patch Notes
- Fixed bugs and issues
- Greatly improved rolling mechanics
- Added new commands and features, including two different rolling modes (Gamble/Quick)
- Added per character settings
- Changed the way actions are handled in order to allow the addon to roll without bugging out even while doing other things at the same time
