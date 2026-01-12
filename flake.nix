{
  description = "zengraf's nix-darwin system flake";

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
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, nix-homebrew
    , homebrew-core, homebrew-cask, nix-index-database }:
    let
      system-config = { pkgs, ... }: {
        nix.enable = false;
        nix.settings.experimental-features = "nix-command flakes";

        nixpkgs.hostPlatform = "aarch64-darwin";
        nixpkgs.config.allowUnfree = true;

        security.pam.services.sudo_local = {
          enable = true;
          touchIdAuth = true;
        };

        users.users.zengraf = {
          shell = pkgs.zsh;
          home = "/Users/zengraf";
        };

        environment.systemPackages = [
          pkgs._1password-cli
          pkgs.bun
          pkgs.comma
          pkgs.mas
          pkgs.ngrok
          pkgs.nodejs_22
          pkgs.postgresql
          pkgs.uv
          pkgs.ruby
          pkgs.vim
          pkgs.zsh
        ];

        homebrew = {
          enable = true;
          brews = [ "sentry-cli" ];
          casks = [
            {
              name = "1password";
              greedy = true;
            }
            "adobe-acrobat-reader"
            {
              name = "arc";
              greedy = true;
            }
            {
              name = "cursor";
              greedy = true;
            }
            "dbeaver-community"
            "docker-desktop"
            "drata-agent"
            "ghostty"
            "google-drive"
            "iina"
            "insomnia"
            "loom"
            "moonlight"
            {
              name = "notion";
              greedy = true;
            }
            {
              name = "obsidian";
              greedy = true;
            }
            {
              name = "slack";
              greedy = true;
            }
            "tailscale"
            "utm"
            {
              name = "zed";
              greedy = true;
            }
            "zoom"
            "zen"
          ];
          masApps = {
            "1Password for Safari" = 1569813296;
            "DaisyDisk" = 411643860;
            "Microsoft Word" = 462054704;
            "Pixelmator Pro" = 1289583905;
            "Telegram" = 747648890;
            "Things 3" = 904280696;
          };
          onActivation.cleanup = "zap";
          onActivation.autoUpdate = true;
          onActivation.upgrade = true;
        };

        system.defaults = {
          dock.autohide = true;
          dock.persistent-apps = [
            "/Applications/Arc.app"
            "/Applications/Telegram.app"
            "/Applications/Slack.app"
            "/Applications/Things3.app"
            "/Applications/1Password.app"
            "/Applications/Obsidian.app"
            "/Applications/Notion.app"
            "/Applications/Zed.app"
            "/Applications/Cursor.app"
            "/Applications/Ghostty.app"
          ];
          dock.show-recents = false;
          finder.FXPreferredViewStyle = "clmv";
          loginwindow.GuestEnabled = false;
          NSGlobalDomain.AppleInterfaceStyle = "Dark";
          NSGlobalDomain.InitialKeyRepeat = 25;
          NSGlobalDomain.KeyRepeat = 2;
        };

        system.activationScripts.extraActivation = {
          text = ''
            if [[ $(uname -m) == "arm64" ]] && ! pgrep oahd >/dev/null 2>&1; then
              echo "installing Rosetta 2..."
              /usr/sbin/softwareupdate --install-rosetta --agree-to-license
            fi
          '';
        };

        system.primaryUser = "zengraf";
        system.configurationRevision = self.rev or self.dirtyRev or null;
        system.stateVersion = 6;
      };

      home-config = {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.zengraf = ./home.nix;

        home-manager.backupFileExtension = "bak";

        home-manager.sharedModules = [ nix-index-database.homeModules.default ];
      };

      homebrew-config = {
        nix-homebrew = {
          enable = true;
          enableRosetta = true;
          user = "zengraf";
          taps = {
            "homebrew/homebrew-core" = homebrew-core;
            "homebrew/homebrew-cask" = homebrew-cask;
          };
          mutableTaps = false;
        };
      };
    in {
      darwinConfigurations.macbook-m4 = nix-darwin.lib.darwinSystem {
        modules = [
          system-config
          home-config
          homebrew-config
          home-manager.darwinModules.home-manager
          nix-homebrew.darwinModules.nix-homebrew
        ];
      };
    };
}
