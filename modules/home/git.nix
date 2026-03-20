{ pkgs, ... }: {
  home.packages = with pkgs; [ delta gnupg tig ];

  programs.git = {
    enable = true;

    settings = {
      user.name = "Hlib Hraif";
      user.email = "hlib.hraif@protonmail.com";
      user.signingkey = "CCAA175508934029";

      commit.gpgsign = true;

      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta.navigate = true;
      merge.conflictStyle = "zdiff3";
    };
  };
}
