{ pkgs }:
let
  inherit (pkgs) lib;

  # Both biome and TypeScript 7 publish their native binaries under <os>-<arch>.
  platform =
    let
      host = pkgs.stdenv.hostPlatform;
    in
    "${if host.isDarwin then "darwin" else "linux"}-${if host.isAarch64 then "arm64" else "x64"}";

  # Zed joins a relative binary.path onto the worktree root exactly once, and the
  # biome extension only reads package.json there — neither finds a project
  # install when the opened root is a subdirectory of the package. Walking
  # ancestors from $PWD does, and Zed spawns language servers with cwd set to the
  # worktree root.
  resolver =
    {
      name,
      project,
      fallback ? null,
      env ? { },
    }:
    let
      giveUp =
        if fallback == null then
          ''echo "${name}: no project install in any ancestor of $PWD" >&2; exit 1''
        else
          ''exec ${fallback.command} ${lib.escapeShellArgs fallback.args} "$@"'';
      script = lib.concatStringsSep "\n" (
        map (k: ''export ${k}="${env.${k}}"'') (builtins.attrNames env)
        ++ [
          "d=$PWD"
          ''while [ "$d" != / ]; do''
        ]
        ++ map (
          p:
          ''if [ -x "$d/${p.path}" ]; then exec "$d/${p.path}" ${
            lib.escapeShellArgs (p.args or [ ])
          } "$@"; fi''
        ) project
        ++ [
          ''d=$(dirname "$d")''
          "done"
          giveUp
        ]
      );
    in
    {
      command = toString (pkgs.writeShellScript "lsp-${name}" script);
      # The resolver bakes each candidate's own arguments, so consumers pass none.
      args = [ ];
    };

  direct = command: args: { inherit command args; };
in
{
  inherit platform;

  tools = {
    # Formatters and linters are project-only: a version mismatch rewrites files.
    biome = {
      zedId = "biome";
      zed.settings.require_config_file = true;
    }
    // resolver {
      name = "biome";
      # The daemon's log filter is a hardcoded DEBUG constant that --log-level
      # cannot reach (biomejs/biome#7538), and a runaway scan writes GB/hour.
      # The path must be a real directory — /dev/null makes biome exit with
      # "Error reading the log directory/files: Not a directory".
      env.BIOME_LOG_PATH = "\${TMPDIR:-/tmp}/zed-biome-logs";
      project = [
        {
          path = "node_modules/@biomejs/cli-${platform}/biome";
          args = [ "lsp-proxy" ];
        }
        {
          path = "node_modules/.bin/biome";
          args = [ "lsp-proxy" ];
        }
      ];
    };

    # Navigation servers fall back: a stale one costs worse hovers, not wrong files.
    typescript = {
      zedId = "typescript-ls";
      claude = {
        plugin = "ts-lsp";
        server = "vtsls";
        description = "TypeScript and JavaScript via tsgo (TS 7), falling back to vtsls";
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
    }
    // resolver {
      name = "typescript";
      # Only the native binary is probed: node_modules/.bin/tsc may be a TS 5
      # shim, which has no --lsp and would fail where vtsls would have worked.
      project = [
        {
          path = "node_modules/@typescript/typescript-${platform}/lib/tsc";
          args = [
            "--lsp"
            "--stdio"
          ];
        }
      ];
      fallback = {
        command = "${pkgs.vtsls}/bin/vtsls";
        args = [ "--stdio" ];
      };
    };

    basedpyright = {
      zedId = "basedpyright";
      # Nested, never a flat "basedpyright.analysis.typeCheckingMode" key: Zed
      # recognizes only "basedpyright" or the two-level "basedpyright.analysis",
      # and on a miss its python adapter inserts its OWN "standard" default, so a
      # flat three-level key is silently downgraded rather than dropped.
      zed.settings.basedpyright.analysis.typeCheckingMode = "all";
      claude = {
        plugin = "py-lsp";
        server = "basedpyright";
        description = "Python via basedpyright";
        extensionToLanguage = {
          ".py" = "python";
          ".pyi" = "python";
        };
        # Zed uses "all"; kept lower here because these land in Claude's
        # context on every edit.
        settings.basedpyright.analysis.typeCheckingMode = "standard";
      };
    }
    // resolver {
      name = "basedpyright";
      project = [
        {
          path = ".venv/bin/basedpyright-langserver";
          args = [ "--stdio" ];
        }
      ];
      fallback = {
        command = "${pkgs.basedpyright}/bin/basedpyright-langserver";
        args = [ "--stdio" ];
      };
    };

    ruff = {
      zedId = "ruff";
    }
    // resolver {
      name = "ruff";
      project = [
        {
          path = ".venv/bin/ruff";
          args = [ "server" ];
        }
      ];
      fallback = {
        command = "${pkgs.ruff}/bin/ruff";
        args = [ "server" ];
      };
    };

    rust-analyzer = {
      zedId = "rust-analyzer";
      claude = {
        plugin = "rs-lsp";
        server = "rust-analyzer";
        description = "Rust via rust-analyzer";
        extensionToLanguage.".rs" = "rust";
      };
    }
    // direct "${pkgs.rust-analyzer}/bin/rust-analyzer" [ ];

    nil = {
      zedId = "nil";
      zed.initialization_options.formatting.command = [ "nixfmt" ];
      claude = {
        plugin = "nix-lsp";
        server = "nil";
        description = "Nix via nil";
        extensionToLanguage.".nix" = "nix";
      };
    }
    // direct "${pkgs.nil}/bin/nil" [ ];

    nu = {
      zedId = "nu";
      claude = {
        plugin = "nu-lsp";
        server = "nushell";
        description = "Nushell via nu --lsp";
        extensionToLanguage.".nu" = "nushell";
      };
    }
    // direct "${pkgs.nushell}/bin/nu" [ "--lsp" ];

    # No project-local form exists for these: nothing installs them into
    # node_modules, so there is nothing to probe for.
    tailwindcss = {
      zedId = "tailwindcss-language-server";
    }
    // direct "${pkgs.tailwindcss-language-server}/bin/tailwindcss-language-server" [ "--stdio" ];

    prisma = {
      zedId = "prisma-language-server";
    }
    // direct "${pkgs.prisma-language-server}/bin/prisma-language-server" [ "--stdio" ];

    json = {
      zedId = "json-language-server";
    }
    // direct "${pkgs.vscode-langservers-extracted}/bin/vscode-json-language-server" [ "--stdio" ];

    css = {
      zedId = "vscode-css-language-server";
    }
    // direct "${pkgs.vscode-langservers-extracted}/bin/vscode-css-language-server" [ "--stdio" ];

    html = {
      zedId = "vscode-html-language-server";
    }
    // direct "${pkgs.vscode-langservers-extracted}/bin/vscode-html-language-server" [ "--stdio" ];

    taplo = {
      zedId = "taplo";
    }
    // direct "${pkgs.taplo}/bin/taplo" [
      "lsp"
      "stdio"
    ];

    docker = {
      zedId = "docker-language-server";
      # `start` speaks stdio unless --address is passed.
    }
    // direct "${pkgs.docker-language-server}/bin/docker-language-server" [ "start" ];

    bash = {
      zedId = "bash-language-server";
      # 0 makes initiateBackgroundAnalysis return before globbing; the crawl runs
      # off the server's own glob and ignores file_scan_exclusions, so left on it
      # walks node_modules and holds a multi-GB heap in permanent GC.
      zed.settings.bashIde.backgroundAnalysisMaxFiles = 0;
    }
    // direct "${pkgs.bash-language-server}/bin/bash-language-server" [ "start" ];

    yaml = {
      zedId = "yaml-language-server";
    }
    // direct "${pkgs.yaml-language-server}/bin/yaml-language-server" [ "--stdio" ];

    ruby-lsp = {
      zedId = "ruby-lsp";
      zed.initialization_options.enabledFeatures.diagnostics = false;
    }
    // direct "${pkgs.ruby-lsp}/bin/ruby-lsp" [ ];

    rubocop = {
      zedId = "rubocop";
      zed.initialization_options.safeAutocorrect = false;
    }
    // direct "${pkgs.rubocop}/bin/rubocop" [ "--lsp" ];
  };
}
