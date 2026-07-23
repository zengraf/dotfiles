{ pkgs, inputs, ... }:
let
  sessionStartContexts = pkgs.writeTextFile {
    name = "claude-session-start-contexts";
    executable = true;
    text = ''
      #!${pkgs.nushell}/bin/nu --no-config-file
      ${builtins.readFile ../../ai/hooks/session-start-contexts.nu}
    '';
  };
  preToolUseContexts = pkgs.writeTextFile {
    name = "claude-pre-tool-use-contexts";
    executable = true;
    text = ''
      #!${pkgs.nushell}/bin/nu --no-config-file
      ${builtins.readFile ../../ai/hooks/pre-tool-use-contexts.nu}
    '';
  };
  preToolUseGitCommit = pkgs.writeTextFile {
    name = "claude-pre-tool-use-git-commit";
    executable = true;
    text = ''
      #!${pkgs.nushell}/bin/nu --no-config-file
      ${builtins.readFile ../../ai/hooks/pre-tool-use-git-commit.nu}
    '';
  };
in
{
  home.packages = [
    pkgs.claude-code
    pkgs.graphify
  ];

  home.file = {
    ".claude/CLAUDE.md".source = ../../ai/CLAUDE.md;
    ".claude/skills/deep-review".source = ../../ai/skills/deep-review;
    ".claude/skills/implement".source = ../../ai/skills/implement;
    ".claude/skills/ctx".source = ../../ai/skills/ctx;
    ".claude/skills/humanizer".source = inputs.humanizer;
    ".claude/skills/graphify".source = "${pkgs.graphify-skill}/skills/graphify";
    ".claude/skills/grilling".source = "${inputs.mattpocock-skills}/skills/productivity/grilling";

    ".claude/settings.json".text = builtins.toJSON {
      permissions.allow = [
        "AskUserQuestion"
        "Read(~/.local/share/claude-contexts/**)"
        "Edit(~/.local/share/claude-contexts/**)"
        "Write(~/.local/share/claude-contexts/**)"
        "Write(~/.local/share/claude-contexts/.gates/**)"
      ];
      hooks.SessionStart = [
        {
          matcher = "startup|resume|clear";
          hooks = [
            {
              type = "command";
              command = "${sessionStartContexts}";
            }
          ];
        }
      ];
      hooks.PreToolUse = [
        {
          matcher = ".*";
          hooks = [
            {
              type = "command";
              command = "${preToolUseContexts}";
            }
          ];
        }
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = "${preToolUseGitCommit}";
            }
          ];
        }
      ];
    };
  };
}
