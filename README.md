# NAtoms
A online multiplayer fork for KleleAtoms .

This is testing fork for online multiplayer implementation in KleleAtoms using ENet.

(This project is not yet finished. You can play it but it's very raw. There are no currently any net synchronization checks.)

## Command line parameters
`-gw <number>` - change grid width (7-30)  
`-gh <number>` - change grid height (4-20)  
`-p1 <type>` - change player 1 type (0 - nothing, 1 - human, 2-4 - AI)  
`-p2 <type>` - change player 2 type  
`-p3 <type>` - change player 3 type  
`-p4 <type>` - change player 4 type  
`-kbmode` - enable keyboard-only mode (with keyboard-controlled cursor)  
`-mobile` - simulate mobile/web mode (fullscreen, limited grid size etc.)  
`-host <ip:port>` - host a multiplayer game (no menu)  
`-connect <ip:port>` - connect to a multiplayer game (no menu)  
`-os <name>` - spoof the target OS (`-os Web` simulates HTML5 love.js version)

## Credits  
**LOVE Development Team** - Löve, a Lua game engine this game runs on.  
**DrPetter** - SFXR, a tool used to make sounds for this game.  

## License
This game is licensed under the MIT License, see [LICENSE](https://github.com/Nightwolf-47/KleleAtoms/blob/main/LICENSE) for details.
