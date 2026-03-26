{ pkgs, ... }:
{
  home.packages = with pkgs; [
    claude-code
    delta
    tig
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.git.settings = {
    core.pager = "delta";
    interactive.diffFilter = "delta --color-only";
    delta.navigate = true;
    merge.conflictStyle = "zdiff3";
  };
}
