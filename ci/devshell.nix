{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      config,
      system,
      ...
    }:
    {
      devShells.default = pkgs.mkShell {
        name = "devshell";

        packages =
          (with pkgs; [
            treefmt
            config.packages."ci:treefmt:sync"
          ])
          ++ [
            inputs.disko.packages.${system}.disko
          ];

        shellHook = ''
          treefmt-sync
        '';
      };
    };
}
