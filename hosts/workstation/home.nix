{ pkgs, ... }:
{
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
    google-cloud-sdk
    graphify
    ruby
    temurin-bin-21 # JDK for the Railsware RPI (Set kata); IntelliJ CE bundles JUnit
  ];

  # IdeaVim config for IntelliJ (install the IdeaVim plugin in-app).
  home.file.".ideavimrc".text = ''
    set scrolloff=5
    set incsearch
    set clipboard+=unnamed
    " keep IDE shortcuts working instead of Vim swallowing them
    sethandler <C-r> a:ide
    sethandler <C-Tab> a:ide
  '';

  home.stateVersion = "25.05";
}
