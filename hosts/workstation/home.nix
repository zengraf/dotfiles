{ pkgs, ... }: {
  imports = [
    ../../modules/home/default.nix
    ../../modules/home/darwin.nix
    ../../modules/home/git.nix
    ../../modules/home/nushell.nix
    ../../modules/home/zed.nix
  ];

  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    _1password-cli
    bun
    claude-code
    google-cloud-sdk
    ngrok
    nodejs_22
    ruby
    uv
  ];
}
