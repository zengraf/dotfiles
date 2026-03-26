{ pkgs, username, ... }: {
  home.username = username;
  home.homeDirectory = "/Users/${username}";

  home.packages = with pkgs; [
    _1password-cli
  ];
}
