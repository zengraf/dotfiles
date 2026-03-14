{ pkgs, ... }:

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

  biomeConfig =
    builtins.listToAttrs (map mkBiomeConfigWithActions biomeLanguagesWithActions)
    // builtins.listToAttrs (map mkBiomeConfig biomeLanguagesOnly);
in {
  home.packages = with pkgs; [ nil nixfmt-classic ];

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
}
