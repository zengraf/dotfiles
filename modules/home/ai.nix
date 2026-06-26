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
in
{
  home.packages = [ pkgs.claude-code ];

  home.file = {
    ".claude/CLAUDE.md".source = ../../ai/CLAUDE.md;
    ".claude/skills/deep-review".source = ../../ai/skills/deep-review;
    ".claude/skills/implement".source = ../../ai/skills/implement;
    ".claude/skills/ctx".source = ../../ai/skills/ctx;
    ".claude/skills/humanizer/SKILL.md".source = "${inputs.humanizer}/SKILL.md";

    ".claude/settings.json".text = builtins.toJSON {
      permissions.allow = [
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
      ];
    };
  };
}
