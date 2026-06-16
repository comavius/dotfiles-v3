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
      packages.rust-dev = pkgs.rust-bin.stable.latest.default.override {
        extensions = [
          "rustfmt"
          "rust-src"
        ];
      };
    };
}
