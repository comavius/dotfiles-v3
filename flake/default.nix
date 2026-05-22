{ inputs, ... }:
let
  nixpkgsConfig = {
    allowUnfreePredicate = import ../non-module/allowUnfreePredicate.nix;
  };
in
{
  imports = [ ./systems.nix ];

  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config = nixpkgsConfig;
      };
    };
}
