{ ... }:
{
  username = "comavius";
  hostname = "usami";
  hasNvidiaGpu = false;

  disk.configSource = "hardware-configuration.nix";
  disk.hardware-configuration = import ./usami/hardware-configuration.nix;
}
