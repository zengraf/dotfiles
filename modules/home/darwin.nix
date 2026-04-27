{
  lib,
  pkgs,
  username,
  ...
}:
{
  home.username = username;
  home.homeDirectory = "/Users/${username}";

  home.packages = with pkgs; [
    _1password-cli
    age-plugin-se
  ];

  programs.nushell.shellAliases.agenix = "agenix -i ~/.config/age/se.txt";

  programs.nushell.extraEnv = ''
    ulimit -Sn 524288
  '';

  home.activation.generateAgeSeKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/.config/age/se.txt" ]; then
      run mkdir -p "$HOME/.config/age"
      run ${pkgs.age-plugin-se}/bin/age-plugin-se keygen \
        --access-control any-biometry-or-passcode \
        -o "$HOME/.config/age/se.txt"
    fi
  '';
}
