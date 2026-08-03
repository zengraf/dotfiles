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

    humanizer = {
      url = "github:blader/humanizer";
      flake = false;
    };

    mattpocock-skills = {
      url = "github:mattpocock/skills";
      flake = false;
    };

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    virby.url = "github:quinneden/virby-nix-darwin";

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
      agenixFor = system: inputs.agenix.packages.${system}.default;
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
            agenix = agenixFor system;
          };
          modules = [
            ./modules/common.nix
            ./modules/darwin
            ./modules/home-manager.nix
            ./hosts/${hostname}
            home-manager.darwinModules.home-manager
            nix-homebrew.darwinModules.nix-homebrew
            inputs.virby.darwinModules.default
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
            agenix = agenixFor system;
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

      # Disposable egress node. Deliberately does not go through mkNixosSystem:
      # it shares nothing with the real machines, and common.nix would put four
      # unused overlays, nixos-rebuild and our CA into every image we store.
      nomadSystem = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./hosts/nomad ];
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
        nomad = nomadSystem;
      };

      packages = {
        x86_64-linux.nomad-image = nomadSystem.config.system.build.nomadImage;
        x86_64-linux.nomad = (import nixpkgs { system = "x86_64-linux"; }).callPackage ./pkgs/nomad {
          inherit self;
        };
        aarch64-darwin.nomad = (import nixpkgs { system = "aarch64-darwin"; }).callPackage ./pkgs/nomad {
          inherit self;
        };
      };
    };
}
