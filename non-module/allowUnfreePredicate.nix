let
  allowedUnfreePackages = [
    "vscode"
    "discord"
    "google-chrome"
  ];
in
pkg: builtins.elem (builtins.parseDrvName pkg.pname).name allowedUnfreePackages
