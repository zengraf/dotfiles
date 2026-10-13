{ pkgs, inputs }:
let
  claudeHook = "${pkgs.claude-hooks}/bin/claude-hook";

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
          command = "${claudeHook} session-start";
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
          command = "${claudeHook} pre-tool-use";
        }
      ];
    }
    {
      matcher = "Bash";
      hooks = [
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
          command = "${claudeHook} post-tool-use";
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
