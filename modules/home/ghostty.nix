{ ... }: {
  programs.ghostty = {
    enable = true;
    package = null;
    settings = {
      theme = "fleet-dark";
      scrollback-limit = 100000;
    };
    themes.fleet-dark = {
      palette = [
        "0=#4a4b4d"
        "1=#eb4056"
        "2=#82d2ce"
        "3=#fad075"
        "4=#4b8dec"
        "5=#eb83e2"
        "6=#2ccce6"
        "7=#e0e1e4"
        "8=#4a4b4d"
        "9=#c7001b"
        "10=#009e6f"
        "11=#e09119"
        "12=#0067e6"
        "13=#eb4dde"
        "14=#00bad6"
        "15=#9d9d9f"
      ];
      background = "#18191b";
      foreground = "#e0e1e4";
      cursor-color = "#4b8dec";
      cursor-text = "#18191b";
      selection-background = "#3e4147";
      selection-foreground = "#e0e1e4";
    };
  };
}
