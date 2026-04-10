{ ... }:
{
  imports = [
    ../../modules/home/default.nix
    ../../modules/home/nushell.nix
  ];

  home.stateVersion = "25.11";
}
