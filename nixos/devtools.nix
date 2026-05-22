{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [

    coreutils-full
    git
    gcc
    clang
  ];
}
