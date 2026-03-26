{ ... }:
{
  programs.git = {
    enable = true;
    lfs.enable = true;

    settings = {
      user.name = "Hlib Hraif";
      user.email = "hlib.hraif@protonmail.com";
    };
  };
}
