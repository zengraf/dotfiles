{ pkgs, ... }:
{
  home.packages = with pkgs; [ vim ];

  programs.nushell = {
    enable = true;
    extraConfig = ''
      $env.config.buffer_editor = "vim"
      $env.config.show_banner = false
      $env.config.history = {
        max_size: 100_000
        sync_on_enter: true
        file_format: "sqlite"
      }
      source ${pkgs.nu_scripts}/share/nu_scripts/aliases/git/git-aliases.nu
    '';
    extraEnv = ''
      # On NixOS, sw/bin also holds sudo without the setuid bit. The wrapper must come first.
      $env.PATH = ($env.PATH | prepend [
        "/run/wrappers/bin"
        ($env.HOME | path join ".nix-profile/bin")
        $"/etc/profiles/per-user/($env.USER)/bin"
        "/run/current-system/sw/bin"
        "/nix/var/nix/profiles/default/bin"
      ])

      # nix-darwin exports this only from set-environment, which zsh and bash source and Nushell does not.
      # Without it the claude wrapper skips NODE_EXTRA_CA_CERTS and TLS fails.
      $env.NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt"
    '';
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
