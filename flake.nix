{
  description = "zengraf's system configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:dbast/agenix/bump";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.darwin.follows = "nix-darwin";
    agenix.inputs.home-manager.follows = "home-manager";
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      nix-homebrew,
      ...
    }@inputs:
    let
      helpers = import ./helpers.nix;
      mkDarwinSystem =
        {
          hostname,
          system ? "aarch64-darwin",
          username ? "zengraf",
          uid ? 501,
        }:
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit
              self
              inputs
              hostname
              system
              username
              uid
              helpers
              ;
          };
          modules = [
            ./modules/common.nix
            ./modules/darwin
            ./modules/home-manager.nix
            ./hosts/${hostname}
            home-manager.darwinModules.home-manager
            nix-homebrew.darwinModules.nix-homebrew
          ];
        };

      mkNixosSystem =
        {
          hostname,
          system ? "x86_64-linux",
          username ? null,
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit
              self
              inputs
              hostname
              system
              username
              helpers
              ;
          };
          modules = [
            ./modules/common.nix
            ./hosts/${hostname}
            inputs.agenix.nixosModules.default
          ]
          ++ nixpkgs.lib.optionals (username != null) [
            home-manager.nixosModules.home-manager
            ./modules/nixos/home-manager.nix
            ./modules/home-manager.nix
          ];
        };
    in
    {
      darwinConfigurations = {
        satellite = mkDarwinSystem { hostname = "satellite"; };
        workstation = mkDarwinSystem { hostname = "workstation"; };
      };

      nixosConfigurations = {
        router = mkNixosSystem {
          hostname = "router";
          username = "zengraf";
        };
      };
    };
}
