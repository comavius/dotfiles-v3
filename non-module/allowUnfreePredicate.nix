let
  allowedUnfreePackages = [
    "vscode"
    "discord"
    "google-chrome"
    "steam"
    "steam-unwrapped"
  ];
in
pkg: builtins.elem (builtins.parseDrvName pkg.pname).name allowedUnfreePackages
