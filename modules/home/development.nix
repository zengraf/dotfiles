{ pkgs, ... }:
{
  home.packages = with pkgs; [
    claude-code
    delta
    devenv
    tig
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    stdlib = ''
      eval "$(${pkgs.devenv}/bin/devenv direnvrc)"
    '';
  };

  programs.git.settings = {
    core.pager = "delta";
    interactive.diffFilter = "delta --color-only";
    delta.navigate = true;
    merge.conflictStyle = "zdiff3";
  };
}
