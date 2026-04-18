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

        packages = with pkgs; [
          treefmt
          config.packages."ci:treefmt:sync"
        ];

        shellHook = ''
          treefmt-sync
        '';
      };
    };
}
