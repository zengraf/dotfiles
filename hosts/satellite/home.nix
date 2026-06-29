{ pkgs, ... }: {
  imports = [
    ../../modules/home/default.nix
    ../../modules/home/darwin.nix
    ../../modules/home/development.nix
    ../../modules/home/ai.nix
    ../../modules/home/git.nix
    ../../modules/home/gpg.nix
    ../../modules/home/nushell.nix
    ../../modules/home/aerospace.nix
    ../../modules/home/zed.nix
    ../../modules/home/ghostty.nix
  ];

  home.packages = with pkgs; [
    openconnect
    openconnect-sso
  ];

  home.stateVersion = "26.05";
}
