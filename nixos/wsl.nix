{
  config,
  inputs,
  lib,
  ...
}:
{
  imports = [ inputs.nixos-wsl.nixosModules.default ];

  disabledModules = [
    ./desktop.nix
    ./printing.nix
  ];

  wsl = {
    enable = true;
    defaultUser = config.my.username;
    wslConf.network.generateHosts = false;
  };

  hardware.graphics.enable = lib.mkForce false;
  systemd.units."tmp-.X11\\x2dunix-X0.mount".enable = lib.mkForce false;

  programs.nix-ld.enable = true;

  home-manager.users.${config.my.username}.disabledModules = [
    ../home/hyprland
    ../home/waybar
    ../home/fcitx.nix
    ../home/weylus.nix
  ];
}
