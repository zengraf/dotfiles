{ pkgs, ... }:
{
  home.packages = with pkgs; [ vim ];

  programs.nushell = {
    enable = true;
    extraConfig = ''
      $env.config.buffer_editor = "vim"
      $env.config.show_banner = false
      source ${pkgs.nu_scripts}/share/nu_scripts/aliases/git/git-aliases.nu
    '';
    extraEnv = ''
      $env.PATH = ($env.PATH | prepend [
        ($env.HOME | path join ".nix-profile/bin")
        $"/etc/profiles/per-user/($env.USER)/bin"
        "/run/current-system/sw/bin"
        "/nix/var/nix/profiles/default/bin"
      ])
    '';
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.fzf.enable = true;

  programs.starship = {
    enable = true;
    enableNushellIntegration = true;
    settings = {
      hostname = {
        ssh_only = true;
        format = "[$hostname]($style) ";
      };
    };
  };
}
