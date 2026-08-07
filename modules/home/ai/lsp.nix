{ config, pkgs }:
let
  marketplace = "dotfiles";
  root = ".local/share/claude-lsp";

  # TypeScript 7 ships its language server inside the `tsc` binary and is roughly
  # an order of magnitude faster than vtsls, but nixpkgs is still on 5.9 and a
  # global tsgo would break repos that predate TS 7 (it rejects `baseUrl`). So
  # prefer the workspace's own TS 7 when it has one, else fall back to vtsls.
  tsLsp = pkgs.writeShellScript "claude-ts-lsp" ''
    tsc=node_modules/.bin/tsc
    if [ -x "$tsc" ]; then
      major=$("$tsc" --version | sed -n 's/^Version \([0-9]*\).*/\1/p')
      if [ -n "$major" ] && [ "$major" -ge 7 ]; then
        exec "$tsc" --lsp --stdio
      fi
    fi
    exec ${pkgs.vtsls}/bin/vtsls --stdio
  '';

  plugins = {
    ts-lsp = {
      description = "TypeScript and JavaScript via tsgo (TS 7), falling back to vtsls";
      servers.vtsls = {
        command = "${tsLsp}";
        extensionToLanguage = {
          ".ts" = "typescript";
          ".mts" = "typescript";
          ".cts" = "typescript";
          ".tsx" = "typescriptreact";
          ".js" = "javascript";
          ".mjs" = "javascript";
          ".cjs" = "javascript";
          ".jsx" = "javascriptreact";
        };
      };
    };
    py-lsp = {
      description = "Python via basedpyright";
      servers.basedpyright = {
        command = "${pkgs.basedpyright}/bin/basedpyright-langserver";
        args = [ "--stdio" ];
        extensionToLanguage = {
          ".py" = "python";
          ".pyi" = "python";
        };
        # Zed uses "all"; kept lower here because these land in Claude's context on every edit
        settings."basedpyright.analysis.typeCheckingMode" = "standard";
      };
    };
    rs-lsp = {
      description = "Rust via rust-analyzer";
      servers.rust-analyzer = {
        command = "${pkgs.rust-analyzer}/bin/rust-analyzer";
        extensionToLanguage = {
          ".rs" = "rust";
        };
      };
    };
    nix-lsp = {
      description = "Nix via nil";
      servers.nil = {
        command = "${pkgs.nil}/bin/nil";
        extensionToLanguage = {
          ".nix" = "nix";
        };
      };
    };
    nu-lsp = {
      description = "Nushell via nu --lsp";
      servers.nushell = {
        command = "${pkgs.nushell}/bin/nu";
        args = [ "--lsp" ];
        extensionToLanguage = {
          ".nu" = "nushell";
        };
      };
    };
  };

  names = builtins.attrNames plugins;

  manifests = builtins.listToAttrs (
    map (name: {
      name = "${root}/plugins/${name}/.claude-plugin/plugin.json";
      value.text = builtins.toJSON {
        inherit name;
        version = "1.0.0";
        author.name = "zengraf";
        description = plugins.${name}.description;
        lspServers = plugins.${name}.servers;
      };
    }) names
  );
in
{
  files = manifests // {
    "${root}/.claude-plugin/marketplace.json".text = builtins.toJSON {
      name = marketplace;
      description = "Nix-managed LSP servers for Claude Code";
      owner.name = "zengraf";
      plugins = map (name: {
        inherit name;
        source = "./plugins/${name}";
        description = plugins.${name}.description;
      }) names;
    };
  };

  # `claude plugin install` writes enabledPlugins into ~/.claude/settings.json, which is a read-only
  # store symlink — so the plugins are declared here rather than installed.
  settings = {
    extraKnownMarketplaces.${marketplace}.source = {
      source = "directory";
      path = "${config.home.homeDirectory}/${root}";
    };
    enabledPlugins = builtins.listToAttrs (
      map (name: {
        name = "${name}@${marketplace}";
        value = true;
      }) names
    );
  };
}
