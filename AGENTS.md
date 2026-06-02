## Overall
- You cannot run command with `sudo` in the terminal. If you want to run `sudo nixos-rebuild switch`, run `nixos-rebuild build` instead or ask me to run it manually.
- When you complete a task, run suitable commands in Continuous Integration section.

## Continuous Integration
```
nix fmt
```
If you changed some `.nix` files, run the following command to check if the configuration is valid.
```
nixos-rebuild build --flake ".#<curent-hostname>"
```
If you changed the configuration with host-specific options, run the following commands instead.
```
nixos-rebuild build --flake ".#maeriberry"
nixos-rebuild build --flake ".#usami"
```
