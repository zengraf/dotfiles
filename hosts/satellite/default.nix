{
  username,
  ...
}:
{
  imports = [ ../../modules/darwin/aerospace.nix ];

  homebrew = {
    casks = [
      "android-studio"
      "calibre"
      "discord"
      "inkscape"
      "prusaslicer"
      "qbittorrent"
    ];
    masApps = {
      "Xcode" = 497799835;
      "Transporter" = 1450874784;
    };
  };

  system.defaults.dock.persistent-apps = [
    "/Applications/Zen.app"
    "/Applications/Telegram.app"
    "/Applications/Things3.app"
    "/Applications/1Password.app"
    "/Applications/Obsidian.app"
    "/Applications/Android Studio.app"
    "/Applications/Zed.app"
    "/Applications/Ghostty.app"
  ];

  home-manager.users.${username} = ./home.nix;

  system.stateVersion = 6;
}
