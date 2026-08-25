{ pkgs }:
let
  inherit (pkgs) lib;
  inherit (import ./tools.nix { inherit pkgs; }) tools;

  # Zed's binary.path short-circuits LspStore::get_language_server_binary before
  # the adapter runs, so this reaches extension-provided servers too and no npm
  # download ever happens. binary.arguments is a full replace, not an append.
  serverEntry = tool: {
    name = tool.zedId;
    value = {
      binary = {
        path = tool.command;
      }
      // lib.optionalAttrs (tool.args != [ ]) { arguments = tool.args; };
    }
    // (tool.zed or { });
  };

  # Copilot resolves its binary in crates/copilot with no settings hook of any
  # kind, and probes npm unconditionally on every launch — so it is the one
  # subsystem that cannot be pinned. Everything else fails loudly instead of
  # quietly downloading.
  npmPolicy = pkgs.writeShellScript "npm-copilot-only" ''
    for arg in "$@"; do
      case "$arg" in
        *@github/copilot-language-server*) exec ${pkgs.nodejs}/bin/npm "$@" ;;
      esac
    done
    echo "npm denied: $* — pin this server with lsp.<id>.binary.path" >&2
    exit 1
  '';

  biomeFormat.formatter.language_server.name = "biome";
  biomeFormatAndFix = biomeFormat // {
    code_actions_on_format = {
      "source.fixAll.biome" = true;
      "source.organizeImports.biome" = true;
    };
  };

  # Order is priority: the first enabled entry is primary. Omitting "..."
  # is what keeps unlisted servers out — with it, Zed sweeps in every
  # registered server, including ones disabled by default.
  typescript = biomeFormatAndFix // {
    language_servers = [
      "typescript-ls"
      "biome"
      "tailwindcss-language-server"
      "!vtsls"
      "!eslint"
      "!typescript-language-server"
    ];
  };
in
{
  lsp = lib.listToAttrs (map serverEntry (lib.attrValues tools));

  node = {
    path = "${pkgs.nodejs-slim}/bin/node";
    npm_path = toString npmPolicy;
  };

  languages = {
    TypeScript = typescript;
    TSX = typescript;
    JavaScript = typescript;

    JSON = biomeFormat // {
      language_servers = [
        "json-language-server"
        "biome"
      ];
    };
    JSONC = biomeFormat // {
      language_servers = [
        "json-language-server"
        "biome"
      ];
    };
    CSS = biomeFormat // {
      language_servers = [
        "vscode-css-language-server"
        "tailwindcss-language-server"
        "biome"
      ];
    };
    # The biome extension declares no SCSS, so the css server covers it; the
    # scss extension stays installed for its grammar with its server off.
    SCSS = {
      language_servers = [
        "vscode-css-language-server"
        "!scss-lsp"
      ];
    };
    HTML = {
      language_servers = [
        "vscode-html-language-server"
        "tailwindcss-language-server"
      ];
    };
    GraphQL = biomeFormat // {
      language_servers = [ "biome" ];
    };

    Python = {
      formatter.language_server.name = "ruff";
      code_actions_on_format = {
        "source.fixAll.ruff" = true;
        "source.organizeImports.ruff" = true;
      };
      language_servers = [
        "basedpyright"
        "ruff"
        "!pylsp"
        "!pyright"
      ];
    };
    Ruby = {
      language_servers = [
        "ruby-lsp"
        "rubocop"
        "!solargraph"
        "!kanayago"
      ];
    };
    Rust = {
      language_servers = [ "rust-analyzer" ];
    };
    Nix = {
      tab_size = 2;
      language_servers = [
        "nil"
        "!nixd"
      ];
    };
    Nu = {
      language_servers = [ "nu" ];
    };
    # Zed's language key for shell scripts, not "Bash" or "Shell".
    "Shell Script" = {
      language_servers = [ "bash-language-server" ];
    };
    YAML = {
      language_servers = [ "yaml-language-server" ];
    };
    TOML = {
      language_servers = [ "taplo" ];
    };
    Dockerfile = {
      language_servers = [ "docker-language-server" ];
    };
    Prisma = {
      language_servers = [ "prisma-language-server" ];
    };
  };
}
