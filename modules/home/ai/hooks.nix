{ pkgs, inputs }:
let
  # baked in via readFile, so editing a hook script needs a home-manager switch to take effect
  mkHook =
    name: script:
    pkgs.writeTextFile {
      inherit name;
      executable = true;
      text = ''
        #!${pkgs.nushell}/bin/nu --no-config-file
        ${builtins.readFile script}
      '';
    };

  sessionStartContexts = mkHook "claude-session-start-contexts" ../../../ai/hooks/session-start-contexts.nu;
  preToolUseContexts = mkHook "claude-pre-tool-use-contexts" ../../../ai/hooks/pre-tool-use-contexts.nu;
  preToolUseGitCommit = mkHook "claude-pre-tool-use-git-commit" ../../../ai/hooks/pre-tool-use-git-commit.nu;
  postToolUseComments = mkHook "claude-post-tool-use-comments" ../../../ai/hooks/post-tool-use-comments.nu;

  # ste-gate falls back to ~/.claude/skills/asd-ste100/scripts/ste-lint.py (our
  # symlink) and writes its state under ~/.claude/ste-gate/, so running it from
  # the read-only store is safe.
  steGate = "${pkgs.python3}/bin/python3 ${inputs.ste-kit}/videos/ep01-the-cure-for-ai-slop/asd-ste100/hooks/ste-gate.py";

  # agterm's Help ▸ Install Agent Status Hooks does an atomic write to
  # ~/.claude/settings.json, replacing the store symlink — so its registrations
  # are mirrored here, pointing at the scripts bundled with the app. The script
  # exits silently when AGTERM_SESSION_ID is unset (any other terminal).
  agtermStatus = "/Applications/agterm.app/Contents/Resources/agent-status/agterm-claude-status.sh";
in
{
  SessionStart = [
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

  UserPromptSubmit = [
    {
      hooks = [
        {
          type = "command";
          command = "${agtermStatus} active --blink";
        }
      ];
    }
  ];

  PreToolUse = [
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
        {
          type = "command";
          command = "${pkgs.rtk}/bin/rtk hook claude";
        }
      ];
    }
  ];

  PostToolUse = [
    {
      matcher = "Edit|Write";
      hooks = [
        {
          type = "command";
          command = "${postToolUseComments}";
        }
      ];
    }
    {
      hooks = [
        {
          type = "command";
          command = "${agtermStatus} active --blink";
        }
      ];
    }
  ];

  Stop = [
    {
      hooks = [
        {
          type = "command";
          command = "${steGate}";
        }
        {
          type = "command";
          command = "${agtermStatus} completed --auto-reset";
        }
      ];
    }
  ];

  Notification = [
    {
      matcher = "permission_prompt";
      hooks = [
        {
          type = "command";
          command = "${agtermStatus} blocked";
        }
      ];
    }
  ];
}
