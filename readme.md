Glob script compiling discord-rpc for Wine. You can download this script for the existing DiscordRPC by discordapp directory or download it as submodule:  
```sh
git clone https://github.com/Dark565/DiscordRPC-Wine --recurse-submodules
```
or
```sh
git clone https://github.com/Dark565/DiscordRPC-Wine
cd DiscordRPC-Wine
git submodule init
git submodule update
```

# Building

To build this library, simply write `./build-wine`, but before it, give this script execution permission, if your user leaks it having 644 (rw r r) file mask as default for example.  
WARNING! If a program which linked the library in compile time will surprise you with an error of type: `Procedure 'Discord_UpdateConnection' not found`, run the command with following argument: '-threads-off'  

# Installing

1. Set override of this library in your wine prefix directory via winecfg:
	- Go to 'library' section,
	- Add override of this library by passing its file name **without** '.dll' suffix,
	- Click 'edit' and choose 'builtin'
2. Copy `discord-rpc.dll.so` to directory of program using that RPC
3. Done. You may test running some DiscordRPC Windows programs. Enjoy!


Original author of discord-rpc is Discord
