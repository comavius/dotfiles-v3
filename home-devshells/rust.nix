{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ inputs.rust-overlay.overlays.default ];
      };
    in
    {
      devShells.rust-dev = pkgs.mkShell {
        name = "rust-dev";

        packages = [
          pkgs.rust-bin.stable.latest.default
        ];
      };
    };
}
