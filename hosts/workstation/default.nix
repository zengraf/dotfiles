{
  username,
  ...
}:
{
  imports = [ ../../modules/darwin/aerospace.nix ];

  homebrew = {
    brews = [ "sentry-cli" ];
    casks = [
      "drata-agent"
      "notion"
      "slack"
      "zoom"
    ];
    masApps = {
      "Microsoft Word" = 462054704;
    };
  };

  system.defaults.dock.persistent-apps = [
    "/Applications/Zen.app"
    "/Applications/Telegram.app"
    "/Applications/Slack.app"
    "/Applications/Things3.app"
    "/Applications/1Password.app"
    "/Applications/Obsidian.app"
    "/Applications/Notion.app"
    "/Applications/Zed.app"
    "/Applications/Ghostty.app"
  ];

  home-manager.users.${username} = ./home.nix;

  system.stateVersion = 6;
}
