{ config, pkgs, ... }:

let
  mkBiomeConfig = lang: {
    name = lang;
    value = { formatter = { language_server = { name = "biome"; }; }; };
  };

  mkBiomeConfigWithActions = lang: {
    name = lang;
    value = {
      formatter = { language_server = { name = "biome"; }; };
      code_actions_on_format = {
        "source.fixAll.biome" = true;
        "source.organizeImports.biome" = true;
      };
    };
  };

  biomeLanguagesWithActions = [ "JavaScript" "TypeScript" "TSX" ];

  biomeLanguagesOnly = [ "JSON" "JSONC" "CSS" "GraphQL" ];

  biomeConfigWithActions = builtins.listToAttrs
    (map mkBiomeConfigWithActions biomeLanguagesWithActions);
  biomeConfigOnly = builtins.listToAttrs (map mkBiomeConfig biomeLanguagesOnly);

  biomeConfig = biomeConfigWithActions // biomeConfigOnly;
in {
  home.stateVersion = "25.05";

  home.username = "zengraf";
  home.homeDirectory = "/Users/zengraf";

  home.packages = [
    pkgs.claude-code
    pkgs.delta
    pkgs.direnv
    pkgs.fzf
    pkgs.google-cloud-sdk
    pkgs.gnupg
    pkgs.nil
    pkgs.nixfmt-classic
    pkgs.tig
  ];

  programs.git = {
    enable = true;

    extraConfig = {
      user.name = "Hlib Hraif";
      user.email = "hlib.hraif@protonmail.com";
      user.signingkey = "CCAA175508934029";

      commit.gpgsign = true;

      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta.navigate = true;
      merge.conflictStyle = "zdiff3";
    };
  };

  programs.zsh = {
    enable = true;

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [ "git" "direnv" "docker-compose" "macos" "sudo" "z" ];
    };

    initContent = ''
      export EDITOR="vim"
      source <(fzf --zsh)
      source $HOME/.config/op/plugins.sh
    '';
  };

  programs.zed-editor = {
    enable = true;

    extensions =
      [ "biome" "dockerfile" "html" "make" "nix" "prisma" "scss" "sql" "toml" ];

    userSettings = {
      features = { edit_prediction_provider = "copilot"; };

      agent = {
        default_profile = "write";
        default_model = {
          provider = "copilot_chat";
          model = "gpt-4o";
        };
      };

      autosave = "on_focus_change";
      vim_mode = true;
      ui_font_size = 16;
      buffer_font_size = 16;
      theme = {
        mode = "system";
        light = "One Light";
        dark = "One Dark";
      };

      languages = biomeConfig // {
        Nix = {
          tab_size = 2;
          language_servers = [ "nil" "!nixd" ];
        };
        Python = {
          language_servers = [ "pyright" "ruff" ];
          formatter = [
            {
              code_actions = {
                "source.organizeImports.ruff" = true;
                "source.fixAll.ruff" = true;
              };
            }
            { language_server.name = "ruff"; }
            {
              external = {
                command = "black";
                arguments = [ "-" ];
              };
            }
          ];
        };
        Ruby = { language_servers = [ "ruby-lsp" "rubocop" "!solargraph" ]; };
      };

      lsp = {
        biome = { settings = { require_config_file = true; }; };
        nil = {
          initialization_options = { formatting.command = [ "nixfmt" ]; };
        };
        pylsp = { initialization_options = { plugins.mypy.enabled = true; }; };
        rubocop = { initialization_options = { safeAutocorrect = false; }; };
        ruby-lsp = {
          initialization_options = {
            enabledFeatures = { diagnostics = false; };
          };
        };
      };
    };
  };

  programs.nix-index = {
    enable = true;
    symlinkToCacheHome = true;
  };

  programs.home-manager.enable = true;
}
