{ config, pkgs, ... }:
let
  username = config.my.username;
in
{
  services.printing = {
    enable = true;
    browsing = true;
    openFirewall = true;
    webInterface = true;
    drivers = with pkgs; [
      gutenprint
      hplip
    ];
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  users.users."${username}".extraGroups = [ "lpadmin" ];

  environment.systemPackages = with pkgs; [
    cups
    system-config-printer
  ];
}
