let
  allowedUnfreePackages = [
  ];
in
pkg: builtins.elem (builtins.parseDrvName pkg.name).name allowedUnfreePackages
