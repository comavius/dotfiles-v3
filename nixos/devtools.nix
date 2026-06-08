{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [

    coreutils-full
    git
    git-lfs
    gcc
    clang
  ];
}
