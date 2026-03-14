{ pkgs, ... }: {
  home.packages = with pkgs; [ comma ];

  programs.nix-index = {
    enable = true;
    symlinkToCacheHome = true;
  };

  programs.home-manager.enable = true;
}
