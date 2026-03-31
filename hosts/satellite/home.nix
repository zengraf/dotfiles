{ ... }: {
  imports = [
    ../../modules/home/default.nix
    ../../modules/home/darwin.nix
    ../../modules/home/development.nix
    ../../modules/home/git.nix
    ../../modules/home/gpg.nix
    ../../modules/home/nushell.nix
    ../../modules/home/aerospace.nix
    ../../modules/home/zed.nix
    ../../modules/home/ghostty.nix
  ];

  home.stateVersion = "26.05";
}
