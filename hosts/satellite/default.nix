{
  lib,
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
      "iloader"
      "inkscape"
      "macfuse"
      "nook"
      "kicad"
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

  services.virby = {
    cores = lib.mkForce 3;
    memory = 12228;
  };

  # `soak` is mandatory, so the daemon sends the router only the deadline soak. The host
  # key is inline, because the daemon runs as root and reads no user known_hosts.
  nix.buildMachines = [
    {
      hostName = "router.zengraf.arpa";
      sshUser = username;
      sshKey = "/Users/${username}/.ssh/deadline-soak-builder";
      protocol = "ssh-ng";
      systems = [ "x86_64-linux" ];
      maxJobs = 1;
      mandatoryFeatures = [ "soak" ];
      publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUpEc3pNY0JmakVISHdHdmNvUDRzYkRucXAzbjg5NWxCKzRUbVdwWitZeVcK";
    }
  ];

  home-manager.users.${username} = ./home.nix;

  system.stateVersion = 6;
}
