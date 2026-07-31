{
  config,
  pkgs,
  inputs,
  ...
}:
let
  hooks = import ./hooks.nix { inherit pkgs; };
  lsp = import ./lsp.nix { inherit config pkgs; };
in
{
  home.packages = [
    pkgs.claude-code
    pkgs.graphify
  ];

  home.file = lsp.files // {
    ".claude/CLAUDE.md".source = ../../../ai/CLAUDE.md;
    ".claude/skills/deep-review".source = ../../../ai/skills/deep-review;
    ".claude/skills/implement".source = ../../../ai/skills/implement;
    ".claude/skills/ctx".source = ../../../ai/skills/ctx;
    ".claude/skills/humanizer".source = inputs.humanizer;
    ".claude/skills/graphify".source = "${pkgs.graphify-skill}/skills/graphify";
    ".claude/skills/grilling".source = "${inputs.mattpocock-skills}/skills/productivity/grilling";

    ".claude/settings.json".text = builtins.toJSON (
      lsp.settings
      // {
        # Edit rules cover every file-editing tool; a Write rule is never matched
        permissions.allow = [
          "AskUserQuestion"
          "Read(~/.local/share/claude-contexts/**)"
          "Edit(~/.local/share/claude-contexts/**)"
          "Edit(~/.local/share/claude-contexts/.gates/**)"
        ];
        mcpServers.linear = {
          type = "sse";
          url = "https://mcp.linear.app/sse";
        };
        inherit hooks;
      }
    );
  };
}
