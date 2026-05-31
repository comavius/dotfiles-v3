let
  allowedUnfreePackages = [
    "vscode"
    "discord"
    "google-chrome"
    "steam"
    "steam-unwrapped"
  ];
  allowedUnfreePackagePrefixes = [
    "cuda-"
    "cuda_"
    "libcublas"
    "libcufft"
    "libcurand"
    "libcusolver"
    "libcusparse"
    "libnpp"
    "libnvjitlink"
    "libnvjpeg"
    "nsight"
    "nvidia-"
  ];

  hasPrefix = prefix: value: builtins.substring 0 (builtins.stringLength prefix) value == prefix;
in
pkg:
let
  name = (builtins.parseDrvName (pkg.pname or pkg.name)).name;
in
builtins.elem name allowedUnfreePackages
|| builtins.any (prefix: hasPrefix prefix name) allowedUnfreePackagePrefixes
