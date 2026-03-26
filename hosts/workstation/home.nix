{ pkgs, ... }: {
  imports = [
    ../../modules/home/default.nix
    ../../modules/home/darwin.nix
    ../../modules/home/development.nix
    ../../modules/home/git.nix
    ../../modules/home/gpg.nix
    ../../modules/home/nushell.nix
    ../../modules/home/zed.nix
  ];

  home.packages = with pkgs; [
    bun
    google-cloud-sdk
    ngrok
    nodejs_22
    ruby
    uv
  ];

  home.stateVersion = "25.05";
}
