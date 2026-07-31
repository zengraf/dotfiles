{ pkgs }:
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
      ];
    }
  ];
}
