{ ... }: {
  imports = [
    ../../modules/home/default.nix
    ../../modules/home/zsh.nix
  ];

  home.stateVersion = "25.11";
}
