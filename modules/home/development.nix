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
      use_devenv() {
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
