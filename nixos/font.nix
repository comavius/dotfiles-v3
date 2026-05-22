{ pkgs, ... }:
{
  fonts = {
    packages = with pkgs; [
      migu
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-monochrome-emoji
    ];
    fontDir.enable = true;
    fontconfig.defaultFonts = {
      emoji = [ "Noto Emoji" ];
      monospace = [
        "Noto Sans Mono"
        "Noto Emoji"
      ];
      sansSerif = [
        "Noto Sans CJK JP"
        "Noto Emoji"
      ];
      serif = [
        "Noto Serif CJK JP"
        "Noto Emoji"
      ];
    };
  };
}
