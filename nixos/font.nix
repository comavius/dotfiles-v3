{ pkgs, ... }:
{
  fonts = {
    packages = with pkgs; [
      migu
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-monochrome-emoji
      roboto
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
