{
  description = "kinugasa-mocap development flake";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    stylix.url = "github:nix-community/stylix/release-25.11";
    treefmt-nix.url = "github:numtide/treefmt-nix";

    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./ci
        ./flake
        ./lib
        ./hosts.nix
      ];
    };
}
