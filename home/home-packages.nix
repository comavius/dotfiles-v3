{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bottom
    gping
    dive
    fastfetch
    firefox
    loupe
    nautilus
    totem
    nixd
    obs-studio
    libreoffice
    go
    go-tools
    clang-tools
    poppler-utils
    wl-clipboard
    vscode
    discord
    google-chrome
    (pkgs.callPackage ./../pkgs/sh4der-jockey.nix { })
    blender
    gimp
    unzip
    ffmpeg-full
    bubblewrap
    gof5
    typst
    tinymist
    codex
    gh
    krita
    tokei
    slack
  ];
}
