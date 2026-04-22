{
  self,
  system,
  pkgs,
  inputs,
  username,
  uid,
  ...
}:
{
  nix.enable = false;

  nixpkgs.hostPlatform = system;

  system.primaryUser = username;

  environment.shells = [ pkgs.nushell ];

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = username;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };
    mutableTaps = false;
  };

  homebrew = {
    enable = true;
    casks = [
      "1password"
      "adobe-acrobat-reader"
      "arc"
      "docker-desktop"
      "ghostty"
      "google-drive"
      "iina"
      "obsidian"
      "tablepro"
      "tailscale-app"
      "zed"
      "zen"
    ];
    masApps = {
      "1Password for Safari" = 1569813296;
      "DaisyDisk" = 411643860;
      "Pixelmator Pro" = 1289583905;
      "Telegram" = 747648890;
      "Things 3" = 904280696;
    };
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };

  environment.systemPackages = with pkgs; [ mas ];

  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
  };

  users.knownUsers = [ username ];
  users.users.${username} = {
    inherit uid;
    home = "/Users/${username}";
  };

  launchd.daemons.limit-maxfiles.serviceConfig = {
    Label = "limit.maxfiles";
    ProgramArguments = [ "launchctl" "limit" "maxfiles" "524288" "524288" ];
    RunAtLoad = true;
    ServiceIPC = false;
  };

  launchd.daemons.limit-maxproc.serviceConfig = {
    Label = "limit.maxproc";
    ProgramArguments = [ "launchctl" "limit" "maxproc" "4096" "8192" ];
    RunAtLoad = true;
    ServiceIPC = false;
  };

  system.activationScripts.extraActivation = {
    text = ''
      if [[ $(uname -m) == "arm64" ]] && ! pgrep oahd >/dev/null 2>&1; then
        echo "installing Rosetta 2..."
        /usr/sbin/softwareupdate --install-rosetta --agree-to-license
      fi
    '';
  };

  system.defaults = {
    NSGlobalDomain.AppleInterfaceStyle = "Dark";
    NSGlobalDomain.InitialKeyRepeat = 25;
    NSGlobalDomain.KeyRepeat = 2;
    loginwindow.GuestEnabled = false;
    dock.autohide = true;
    dock.show-recents = false;
    finder.FXPreferredViewStyle = "clmv";
  };

  system.configurationRevision = self.rev or self.dirtyRev or null;
}
