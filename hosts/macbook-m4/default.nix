{ pkgs, username, ... }: {
  networking.hostName = "macbook-m4";

  nixpkgs.hostPlatform = "aarch64-darwin";

  system.primaryUser = username;

  environment.systemPackages = with pkgs; [
    _1password-cli
    bun
    mas
    ngrok
    nodejs_22
    postgresql
    uv
    ruby
  ];

  homebrew = {
    enable = true;
    brews = [ "sentry-cli" ];
    casks = [
      { name = "1password"; greedy = true; }
      "adobe-acrobat-reader"
      { name = "arc"; greedy = true; }
      { name = "cursor"; greedy = true; }
      "dbeaver-community"
      "docker-desktop"
      "drata-agent"
      "ghostty"
      "google-drive"
      "iina"
      "insomnia"
      "loom"
      "moonlight"
      { name = "notion"; greedy = true; }
      { name = "obsidian"; greedy = true; }
      { name = "slack"; greedy = true; }
      "tailscale"
      "utm"
      { name = "zed"; greedy = true; }
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
      "/Applications/Arc.app"
      "/Applications/Telegram.app"
      "/Applications/Slack.app"
      "/Applications/Things3.app"
      "/Applications/1Password.app"
      "/Applications/Obsidian.app"
      "/Applications/Notion.app"
      "/Applications/Zed.app"
      "/Applications/Cursor.app"
      "/Applications/Ghostty.app"
    ];
  };

  system.defaults.finder.FXPreferredViewStyle = "clmv";

  home-manager.users.${username} = ./home.nix;
}
