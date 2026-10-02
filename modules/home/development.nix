{ pkgs, agenix, ... }:
{
  home.packages = [
    agenix
  ] ++ (with pkgs; [
    delta
    devenv
    difftastic
    gh
    mergiraf
    tig
  ]);

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    stdlib = ''
      # Zed and other FSEvents consumers watch the whole worktree and cannot
      # exclude a subtree. Postgres writes under .devenv/state overflow the
      # event queue, so the state lives outside the tree behind a symlink.
      # A real directory is left alone: it may hold a live cluster.
      use_devenv() {
        local state_home="''${XDG_STATE_HOME:-$HOME/.local/state}/devenv"
        local state="$state_home/$(basename "$PWD")-$(printf %s "$PWD" | ${pkgs.coreutils}/bin/sha256sum | cut -c1-8)"
        if [[ -d .devenv/state && ! -L .devenv/state ]]; then
          log_status "devenv: .devenv/state is a real directory, not moved to $state"
        else
          mkdir -p "$state" .devenv
          [[ -L .devenv/state ]] || ln -s "$state" .devenv/state
        fi
        eval "$(${pkgs.devenv}/bin/devenv direnvrc)"
        use_devenv "$@"
      }
    '';
  };

  programs.git.attributes = [ "* merge=mergiraf" ];

  programs.git.settings = {
    core.pager = "delta";
    interactive.diffFilter = "delta --color-only";
    delta.navigate = true;
    merge.conflictStyle = "zdiff3";

    difftool.prompt = false;
    difftool.difftastic.cmd = "difft \"$LOCAL\" \"$REMOTE\"";
    alias.dft = "difftool -t difftastic";

    merge.mergiraf = {
      name = "mergiraf";
      driver = "${pkgs.mergiraf}/bin/mergiraf merge --git %O %A %B -s %S -x %X -y %Y -p %P -l %L";
    };
  };
}
