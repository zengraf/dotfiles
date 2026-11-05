{ pkgs, lib, ... }:
let
  lspZed = import ./lsp/zed.nix { inherit pkgs; };

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
    "nu"
    "prisma"
    "ruby"
    "scss"
    "slint"
    "sql"
    "svelte"
    "terraform"
    "toml"
    "tsgo"
  ];
in
{
  # nil resolves nixfmt off PATH; the servers themselves are absolute store
  # paths in lsp/tools.nix and need no entry here.
  home.packages = [ pkgs.nixfmt ];

  # auto_install_extensions only adds, so an extension dropped from the list
  # stays installed.
  home.activation.zedPrune = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    z="$HOME/Library/Application Support/Zed"
    for e in "$z"/extensions/installed/*; do
      [ -e "$e" ] || continue
      case " ${lib.concatStringsSep " " extensions} " in
        *" $(basename "$e") "*) ;;
        *) run rm -rf "$e" "$z/extensions/work/$(basename "$e")" ;;
      esac
    done
    run rm -rf "$z/languages" "$z/prettier" "$z/external_agents" "$z"/node/node-v*
  '';

  programs.zed-editor = {
    enable = true;

    inherit extensions;

    userSettings = {
      load_direnv = "direct";

      inherit (lspZed) lsp languages node;

      # An extension auto-update swapped the project's pinned biome for a build
      # whose daemon spins forever on workspace rescans (biomejs/biome#7538).
      # Binary resolution no longer runs their wasm, but the pin keeps the
      # server ids stable.
      auto_update_extensions = {
        biome = false;
        tsgo = false;
      };

      edit_predictions = {
        provider = "copilot";
        mode = "subtle";
        enabled_in_text_threads = false;
        copilot = {
          proxy = null;
          proxy_no_verify = null;
          enterprise_uri = null;
        };
      };

      # Agentic flows run in agterm. Only the panel and its threads sidebar go:
      # disable_ai would also switch off Copilot edit predictions.
      agent = {
        enabled = false;
        button = false;
      };

      autosave = "on_focus_change";
      helix_mode = true;
      vim_mode = true;
      ui_font_size = 16;
      buffer_font_size = 16;
      theme = {
        mode = "system";
        light = "Fleet Light";
        dark = "Fleet Dark";
      };

      diff_view_style = "split";
      # Zed 1.20 docks these right by default (the agentic layout). Explicit
      # because mutableUserSettings merges into the existing settings.json, so a
      # key removed here keeps its old value there.
      project_panel.dock = "left";
      outline_panel.dock = "left";
      collaboration_panel.dock = "left";
      git_panel = {
        dock = "left";
        tree_view = false;
      };

      # Replaces Zed's defaults rather than extending them; the stock entries
      # have to be repeated.
      file_scan_exclusions = [
        "**/.git"
        "**/.svn"
        "**/.hg"
        "**/.jj"
        "**/CVS"
        "**/.DS_Store"
        "**/Thumbs.db"
        "**/.classpath"
        "**/.settings"
        "**/.devenv"
        "**/.direnv"
      ];
    };
  };
}
