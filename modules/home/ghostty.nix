{ ... }:
{
  programs.ghostty = {
    enable = true;
    package = null;
    settings = {
      theme = "fleet-dark";
      scrollback-limit = 10000000;
    };
    themes.fleet-dark = import ./fleet-dark.nix;
  };
}
