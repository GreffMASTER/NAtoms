# NAtoms
An online multiplayer fork for KleleAtoms.

This fork implements online multiplayer to KleleAtoms using ENet thru UDP. To start a server/connect to the game, please refer to "Command line parameters" section.  

(This project is not yet finished. The game is playable but there's a chance that the game might desynchronize.)

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
`-nick <name>` - set your ingame nick (default "Guest")  
`-connect <ip>` - connect to a multiplayer game (no menu)  
`-os <name>` - spoof the target OS (`-os Web` simulates HTML5 love.js version)

## Credits  
**LOVE Development Team** - Löve, a Lua game engine this game runs on.  
**DrPetter** - SFXR, a tool used to make sounds for this game.  

## License
This game is licensed under the MIT License, see [LICENSE](https://github.com/Nightwolf-47/KleleAtoms/blob/main/LICENSE) for details.
