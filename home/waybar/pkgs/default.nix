{
  callPackage,
  dotfilesRepositoryPath,
}:
{
  waybarAudioControl = callPackage ./waybar-audio-control.nix { };
  waybarNixosConfigurationStatus = callPackage ./waybar-nixos-configuration-status.nix {
    inherit dotfilesRepositoryPath;
  };
}
