{ ... }:
{
  username = "comavius";
  hostname = "usami";
  hasNvidiaGpu = true;

  disk.configSource = "hardware-configuration.nix";
  disk.hardware-configuration = import ./usami/hardware-configuration.nix;
}
