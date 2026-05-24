{ pkgs, ... }:
{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      addons = [
        pkgs.fcitx5-mozc
      ];
      waylandFrontend = true;
      settings.inputMethod = {
        GroupOrder."0" = "Default";
        "Groups/0" = {
          Name = "Default";
          "Default Layout" = "jp106";
          DefaultIM = "jp106";
        };
        "Groups/0/Items/0".Name = "jp106";
        "Groups/0/Items/1".Name = "mozc";
      };
    };
  };
}
