{ pkgs, ... }:

let
  mkBiomeConfig = lang: {
    name = lang;
    value = {
      formatter = {
        language_server = {
          name = "biome";
        };
      };
    };
  };

  mkBiomeConfigWithActions = lang: {
    name = lang;
    value = {
      formatter = {
        language_server = {
          name = "biome";
        };
      };
      code_actions_on_format = {
        "source.fixAll.biome" = true;
        "source.organizeImports.biome" = true;
      };
    };
  };

  biomeLanguagesWithActions = [
    "JavaScript"
    "TypeScript"
    "TSX"
  ];
  biomeLanguagesOnly = [
    "JSON"
    "JSONC"
    "CSS"
    "GraphQL"
  ];

  biomeConfig =
    builtins.listToAttrs (map mkBiomeConfigWithActions biomeLanguagesWithActions)
    // builtins.listToAttrs (map mkBiomeConfig biomeLanguagesOnly);
in
{
  home.packages = with pkgs; [
    nil
    nixfmt
  ];

  programs.zed-editor = {
    enable = true;

    extensions = [
      "biome"
      "dart"
      "dockerfile"
      "fleet-themes"
      "git-firefly"
      "html"
      "kotlin"
      "make"
      "nix"
      "prisma"
      "scss"
      "sql"
      "toml"
    ];

    userSettings = {
      load_direnv = "direct";

      agent_servers = {
        claude-acp = {
          type = "registry";
          default_config_options = {
            model = "opus";
          };
        };
      };

      edit_predictions = {
        provider = "copilot";
        mode = "subtle";
        enabled_in_text_threads = false;
      };

      agent = {
        default_profile = "ask";
        default_model = {
          provider = "copilot_chat";
          model = "gpt-4o";
        };
      };

      autosave = "on_focus_change";
      helix_mode = true;
      ui_font_size = 16;
      buffer_font_size = 16;
      theme = {
        mode = "system";
        light = "Fleet Light";
        dark = "Fleet Dark";
      };

      languages = biomeConfig // {
        Nix = {
          tab_size = 2;
          language_servers = [
            "nil"
            "!nixd"
          ];
        };
        Python = {
          language_servers = [
            "basedpyright"
            "ruff"
          ];
          code_actions_on_format = {
            "source.fixAll.ruff" = true;
            "source.organizeImports.ruff" = true;
          };
          formatter = {
            language_server = {
              name = "ruff";
            };
          };
        };
        Ruby = {
          language_servers = [
            "ruby-lsp"
            "rubocop"
            "!solargraph"
          ];
        };
      };

      lsp = {
        biome = {
          settings = {
            require_config_file = true;
          };
        };
        nil = {
          initialization_options = {
            formatting.command = [ "nixfmt" ];
          };
        };
        pylsp = {
          initialization_options = {
            plugins.mypy.enabled = true;
          };
        };
        basedpyright = {
          settings = {
            "basedpyright.analysis.typeCheckingMode" = "all";
          };
        };
        rubocop = {
          initialization_options = {
            safeAutocorrect = false;
          };
        };
        ruby-lsp = {
          initialization_options = {
            enabledFeatures = {
              diagnostics = false;
            };
          };
        };
      };
    };
  };
}
