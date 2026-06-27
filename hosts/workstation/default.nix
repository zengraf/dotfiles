{
  username,
  pkgs,
  ...
}:
{
  imports = [ ../../modules/darwin/aerospace.nix ];

  homebrew = {
    brews = [ "sentry-cli" ];
    casks = [
      "drata-agent"
      "intellij-idea-ce"
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

  # Expose the nix-store Temurin JDK as a standard macOS JDK bundle so IntelliJ
  # (and /usr/libexec/java_home) auto-detect it without a manual SDK setup.
  system.activationScripts.extraActivation.text = ''
    mkdir -p /Library/Java/JavaVirtualMachines
    ln -sfn ${pkgs.temurin-bin-21}/Library/Java/JavaVirtualMachines/temurin-21.jdk \
      /Library/Java/JavaVirtualMachines/temurin-21-nix.jdk
  '';

  system.stateVersion = 6;
}
