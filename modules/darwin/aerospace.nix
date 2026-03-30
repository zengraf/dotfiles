{ inputs, ... }:
{
  nix-homebrew.taps."nikitabobko/homebrew-tap" = inputs.homebrew-aerospace;
  homebrew.casks = [ "nikitabobko/tap/aerospace" ];

  # Disable Mission Control ctrl+arrow shortcuts to free them for aerospace
  system.defaults.CustomUserPreferences."com.apple.symbolichotkeys" = {
    AppleSymbolicHotKeys = {
      # Mission Control (ctrl+up)
      "32" = {
        enabled = false;
      };
      # Application Windows (ctrl+down)
      "33" = {
        enabled = false;
      };
      # Move left a space (ctrl+left)
      "79" = {
        enabled = false;
      };
      # Move right a space (ctrl+right)
      "81" = {
        enabled = false;
      };
    };
  };
}
