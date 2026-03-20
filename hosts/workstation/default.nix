{
  pkgs,
  hostname,
  username,
  ...
}:
{
  networking.hostName = hostname;

  system.primaryUser = username;

  environment.shells = [ pkgs.nushell ];

  users.users.${username}.shell = pkgs.nushell;

  homebrew = {
    enable = true;
    brews = [ "sentry-cli" ];
    casks = [
      "1password"
      "adobe-acrobat-reader"
      "arc"
      "dbeaver-community"
      "docker-desktop"
      "drata-agent"
      "ghostty"
      "google-drive"
      "iina"
      "insomnia"
      "notion"
      "obsidian"
      "slack"
      "tailscale-app"
      "zed"
      "zoom"
      "zen"
    ];
    masApps = {
      "1Password for Safari" = 1569813296;
      "DaisyDisk" = 411643860;
      "Microsoft Word" = 462054704;
      "Pixelmator Pro" = 1289583905;
      "Telegram" = 747648890;
      "Things 3" = 904280696;
    };
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };

  system.defaults.dock = {
    autohide = true;
    show-recents = false;
    persistent-apps = [
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
  };

  system.defaults.finder.FXPreferredViewStyle = "clmv";

  home-manager.users.${username} = ./home.nix;
}
