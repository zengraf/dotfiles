{ username, ... }: {
  home.username = username;
  home.homeDirectory = "/Users/${username}";

  programs.zsh.oh-my-zsh.plugins = [ "macos" ];
}
