{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my;
in
{
  boot = lib.mkMerge [
    {
      loader = {
        systemd-boot = {
          enable = true;
          configurationLimit = 50;
        };
        efi.canTouchEfiVariables = true;
      };
    }
    (lib.mkIf cfg.hasNvidiaGpu {
      blacklistedKernelModules = [ "nouveau" ];
      kernelParams = [
        "nvidia-drm.modeset=1"
        "nvidia-drm.fbdev=1"
      ];
    })
  ];

  zramSwap = lib.mkIf (cfg.zramSwapSizeGiB != null) {
    enable = true;
    memoryMax = cfg.zramSwapSizeGiB * 1024 * 1024 * 1024;
    priority = 100;
  };

  services.xserver.videoDrivers = lib.mkIf cfg.hasNvidiaGpu [ "nvidia" ];

  hardware.nvidia = lib.mkIf cfg.hasNvidiaGpu {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    powerManagement.enable = true;
  };

  environment.systemPackages = lib.mkIf cfg.hasNvidiaGpu (
    with pkgs;
    [
      cudaPackages.cudatoolkit
    ]
  );

  networking = {
    hostName = cfg.hostname;
    networkmanager.enable = true;
  };

  nix.settings = {
    substituters = [
      "https://cache.nixos-cuda.org"
    ];
    trusted-public-keys = [
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  nixpkgs.config.cudaSupport = lib.mkIf cfg.hasNvidiaGpu true;

  system = {
    configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
    stateVersion = cfg.stateVersion;
  };

  users.users."${cfg.username}" = {
    initialPassword = cfg.initialPassword;
  };
}
