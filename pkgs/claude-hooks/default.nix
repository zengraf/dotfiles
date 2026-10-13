{ mkNuApp }:
mkNuApp {
  pname = "claude-hooks";
  src = ./.;
  bins.claude-hook = "claude-hook.nu";
  tests = [ "test.nu" ];
  meta.description = "Claude Code hooks: task-context gate, commit guard, comment review";
}
