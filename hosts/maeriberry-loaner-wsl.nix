{ config, ... }:
{
  username = "comavius";
  hostname = "maeriberry-loaner-wsl";
  dotfilesRepositoryPath = "${config.homeDirectory}/projects/dotfiles-v3";
  isWsl = true;
}
