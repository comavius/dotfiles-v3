{
  config,
  pkgs,
  ...
}:
let
  username = config.my.username;
  weylus = pkgs.callPackage ../pkgs/weylus.nix { };
in
{
  services.xserver.enable = false;

  services.greetd = {
    enable = true;
    settings.default_session = {
      user = username;
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd ${pkgs.hyprland}/bin/start-hyprland";
    };
  };

  systemd.services.greetd = {
    after = [ "home-manager-${username}.service" ];
    wants = [ "home-manager-${username}.service" ];
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  programs.weylus = {
    enable = true;
    openFirewall = false;
    package = weylus;
    users = [ username ];
  };

  hardware.graphics.enable = true;
  programs.nix-ld.enable = true;
  security.rtkit.enable = true;
  security.pam.services.hyprlock = { };

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
  };

  programs.steam.enable = true;
}
