{
  description = "kinugasa-mocap development flake";

  inputs = {
    disko.url = "github:nix-community/disko";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    stylix.url = "github:nix-community/stylix/release-26.05";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    kaleido.url = "git+ssh://git@github.com/comavius/kaleido.git";

    disko.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
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
        ./hosts
        ./home-devshells
      ];
    };
}
