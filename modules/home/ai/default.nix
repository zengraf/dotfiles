{
  pkgs,
  inputs,
  ...
}:
let
  hooks = import ./hooks.nix { inherit pkgs inputs; };

  # `-n`/`--no-config-file` would silently override `--config`, so the wrapper
  # passes `--config` alone.
  nua = pkgs.writeShellScriptBin "nua" ''
    exec ${pkgs.nushell}/bin/nu --config ${../../../ai/agent.nu} -c "$*"
  '';

  # Upstream ships no disable-model-invocation and its description auto-triggers
  # on phrases like "be brief"; patched to manual-only.
  caveman = pkgs.runCommand "caveman-skill" { } ''
    cp -r ${inputs.caveman}/skills/caveman $out
    chmod -R u+w $out
    sed -i '/^name: caveman$/a disable-model-invocation: true' $out/SKILL.md
  '';
in
{
  home.packages = [
    pkgs.claude-code
    pkgs.graphify
    pkgs.ripgrep
    pkgs.rtk
    nua
  ];

  home.file = {
    ".claude/CLAUDE.md".source = ../../../ai/CLAUDE.md;
    ".claude/skills/deep-review".source = ../../../ai/skills/deep-review;
    ".claude/skills/implement".source = ../../../ai/skills/implement;
    ".claude/skills/ctx".source = ../../../ai/skills/ctx;
    ".claude/skills/humanizer".source = inputs.humanizer;
    ".claude/skills/graphify".source = "${pkgs.graphify-skill}/skills/graphify";
    ".claude/skills/grilling".source = "${inputs.mattpocock-skills}/skills/productivity/grilling";
    ".claude/skills/asd-ste100".source = "${inputs.ste-kit}/videos/ep01-the-cure-for-ai-slop/asd-ste100";
    ".claude/skills/caveman".source = caveman;

    "Library/Application Support/rtk/config.toml".text = ''
      [hooks]
      exclude_commands = ["nu", "nua"]
    '';

    ".claude/settings.json".text = builtins.toJSON {
      permissions.allow = [
        "AskUserQuestion"
        "Read(~/.local/share/claude-contexts/**)"
        "Edit(~/.local/share/claude-contexts/**)"
        "Edit(~/.local/share/claude-contexts/.gates/**)"
      ];
      # /model advertises no Opus 5 row for this account
      env.ANTHROPIC_DEFAULT_OPUS_MODEL = "claude-opus-5[1m]";
      outputStyle = "Concise";
      mcpServers.linear = {
        type = "sse";
        url = "https://mcp.linear.app/sse";
      };
      # `claude plugin install` writes enabledPlugins into this file, which is a
      # read-only store symlink — so the agterm plugin is declared instead.
      extraKnownMarketplaces.agterm.source = {
        source = "github";
        repo = "umputun/agterm";
      };
      enabledPlugins."agterm@agterm" = true;
      inherit hooks;
    };
  };
}
