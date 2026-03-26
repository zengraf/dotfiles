{ pkgs, ... }:
{
  home.packages = with pkgs; [
    claude-code
    delta
    gnupg
    tig
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.git.settings = {
    user.signingkey = "CCAA175508934029";

    commit.gpgsign = true;

    core.pager = "delta";
    interactive.diffFilter = "delta --color-only";
    delta.navigate = true;
    merge.conflictStyle = "zdiff3";
  };
}
