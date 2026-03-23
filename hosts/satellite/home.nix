{ ... }: {
  imports = [
    ../../modules/home/default.nix
    ../../modules/home/darwin.nix
    ../../modules/home/git.nix
    ../../modules/home/nushell.nix
    ../../modules/home/zed.nix
  ];

  home.stateVersion = "26.05";
}
