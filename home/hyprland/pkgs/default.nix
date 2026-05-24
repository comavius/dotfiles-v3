{ callPackage }:
{
  hyprScreenRecord = callPackage ./hypr-screen-record.nix { };
  hyprScreenRecordService = callPackage ./hypr-screen-record-service.nix { };
  hyprScreenshot = callPackage ./hypr-screenshot.nix { };
}
