# NAtoms
An online multiplayer fork for KleleAtoms.  

![NAtoms Banner](https://repository-images.githubusercontent.com/478681548/15e295f7-7050-40b9-a7fd-78ddedbf8725)  
(This project is still in development. There might be some bugs in the code and some features might change over time.)  

This fork implements online multiplayer to KleleAtoms thru UDP using ENet.  

## Features
- Play KleleAtoms with your buddies (up to 4 players)
- Player lobby (waiting room)
- Avatar system
- Chat system
- Chat commands
- Admin tools

## Possible Planned Features
- Vote system
- Dedicated server mode

## Aditional notes
In order to host a server, you need to have a public ip and an open UDP port on your router (default 5047).  

To set your own avatar, you must open the network menu, click on the avatar button next to the user name field and drag a supported image file onto the game window.  
You can also replace it manually by adding a 64x64 png image called `avatar.png` to the app data directory.  
On Windows it should be in `%APPDATA%\LOVE\kleleatoms`  
On Linux it should be in `~/.local/share/love/kleleatoms`  

## How to install
Download the [latest love file](https://github.com/GreffMASTER/NAtoms/releases/latest) and run it via Love2d executable.  

## Command line parameters
`-gw <number>` - change grid width (7-30)  
`-gh <number>` - change grid height (4-20)  
`-p1 <type>` - change player 1 type (0 - nothing, 1 - human, 2-4 - AI)  
`-p2 <type>` - change player 2 type  
`-p3 <type>` - change player 3 type  
`-p4 <type>` - change player 4 type  
`-kbmode` - enable keyboard-only mode (with keyboard-controlled cursor)  
`-mobile` - simulate mobile/web mode (fullscreen, limited grid size etc.)  
`-port` - set server port (default 5047)  
`-host <ip>` - host a multiplayer game (no menu)  
`-nick <name>` - set your ingame nick (default "Player")  
`-connect <ip>` - connect to a multiplayer game (no menu)  
`-os <name>` - spoof the target OS (`-os Web` simulates HTML5 love.js version)

## Credits  
**LOVE Development Team** - Löve, a Lua game engine this game runs on.  
**DrPetter** - SFXR, a tool used to make music samples and sounds for this game.  

## License
This game is licensed under the MIT License, see [LICENSE](https://github.com/GreffMASTER/NAtoms/blob/main/LICENSE) for details.
