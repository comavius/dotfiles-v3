{ inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  perSystem =
    {
      pkgs,
      config,
      ...
    }:
    {
      treefmt = {
        projectRootFile = "flake.nix";
        programs.biome = {
          enable = true;
          formatCommand = "format";
          settings = builtins.fromJSON (builtins.readFile ../biome.json);
        };
        programs.nixfmt.enable = true;
      };

      packages."ci:treefmt:sync" = pkgs.writeShellApplication {
        name = "treefmt-sync";
        text = ''
          echo "Updating .treefmt.toml ..." >&2
          GIT_ROOT=$(git rev-parse --show-toplevel)
            cp -f "$TREEFMT_CONFIG_FILE" "$GIT_ROOT"/treefmt.toml
            echo "Updated .treefmt.toml ..." >&2
        '';
        runtimeInputs = with pkgs; [ git ];
        runtimeEnv = {
          TREEFMT_CONFIG_FILE = config.treefmt.build.configFile;
        };
      };
    };
}
