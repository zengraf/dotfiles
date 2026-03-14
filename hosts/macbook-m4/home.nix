{ pkgs, ... }: {
  imports = [
    ../../modules/home/default.nix
    ../../modules/home/darwin.nix
    ../../modules/home/git.nix
    ../../modules/home/zsh.nix
    ../../modules/home/zed.nix
  ];

  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    claude-code
    google-cloud-sdk
  ];

  programs.zsh.oh-my-zsh.plugins = [ "docker-compose" ];
  programs.zsh.initExtra = ''
    source $HOME/.config/op/plugins.sh
  '';
}
