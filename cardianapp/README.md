# cardian_discord
The Discord Bot for the Cardian add-on for FFXI

Do NOT put this folder in your Windower or Windows directory!  Both will interfere with the bot!

You will need Luvit, Discordia and the Windower addon in addition to this!
(Install Luvit and Discordia in your Cardian_Discord folder by navigating to the folder in CMD and processing the commands provided)

Luvit - https://luvit.io/
CMD Command (Run this in CMD after navigating to your Cardian_Discord folder): 

	PowerShell -NoProfile -ExecutionPolicy unrestricted -Command "[Net.ServicePointManager]::SecurityProtocol = 'Tls12'; iex ((new-object net.webclient).DownloadString('https://github.com/luvit/lit/raw/master/get-lit.ps1'))"

*ADD your Cardian_Discord folder to PATH*


Discordia - https://github.com/SinisterRectus/Discordia
CMD Command (Run this in CMD after navigating to your Cardian_Discord folder):

	lit install SinisterRectus/discordia


A Bot registered with Discord:
https://discordapp.com/developers/applications/me

Follow all the way through "Create a Bot User" and make sure to get the APP BOT USER token.
Join your bot to your channel using the OAUTH2 URL GENERATOR. Set Scope as 'bot' and permissions as 'Administrator'. Copy the generated URL and go to it in browser. Follow prompts and select your server to authorize bot access.


Setup:

	-Create folder (outside Windower directory) and place these files in that folder

	-Install Luvit (for handling Lua / networking)

	-Install Discordia (for handling Discord connection commands)

	-Modify discord_info.lua and fill in your information.  To get user_id and channel information, enter Developer Mode in Discord.  It's near the bottom in Discord's Settings > Appearance > Advanced > Developer Mode.  After entering Developer Mode, right click on the element whose ID you need and select the bottom option: Copy ID.

Running Cardian_Discord:
	Drag the file "cardian_bot" into the application "luvit", a DOS window will show up if done correctly.  If this window closes, the bot is not active.


Run this in conjunction with the FFXI Windower addon "Cardian"
https://github.com/sjkinnett1/cardian
