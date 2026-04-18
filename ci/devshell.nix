{ ... }:
{
  perSystem =
    {
      pkgs,
      config,
      ...
    }:
    {
      devShells.default = pkgs.mkShell {
        name = "devshell";

        packages = [
          config.packages."ci:treefmt:sync"
        ];

        shellHook = ''
          treefmt-sync
        '';
      };
    };
}
