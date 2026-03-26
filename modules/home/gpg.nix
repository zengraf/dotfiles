{ pkgs, ... }:
{
  home.packages = with pkgs; [ gnupg ];

  programs.gpg = {
    enable = true;

    publicKeys = [
      {
        source = ../../gpg/public.asc;
        trust = "ultimate";
      }
    ];
  };

  programs.git.settings = {
    user.signingkey = "CCAA175508934029";
    commit.gpgsign = true;
  };
}
