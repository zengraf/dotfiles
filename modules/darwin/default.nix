{ self, pkgs, inputs, username, ... }: {
  nix.enable = false;

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

  environment.systemPackages = with pkgs; [ mas ];

  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
  };

  users.users.${username}.home = "/Users/${username}";

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
  };

  system.configurationRevision = self.rev or self.dirtyRev or null;
  system.stateVersion = 6;
}
