{ lib, config, ... }:
let
  cfg = config.my;
in
{
  virtualisation.vmVariant.virtualisation = lib.mkIf cfg.isVm {
    memorySize = 2048;
    cores = 2;
  };
}
