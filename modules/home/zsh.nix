{ pkgs, ... }: {
  home.packages = with pkgs; [ direnv fzf vim z ];

  programs.zsh = {
    enable = true;

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [ "git" "direnv" "sudo" "z" ];
    };

    initContent = ''
      export EDITOR="vim"
      source <(fzf --zsh)
    '';
  };
}
