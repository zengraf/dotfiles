{ lib, ... }:
let
  theme = import ./fleet-dark.nix;
in
{
  # Inline color keys instead of `theme = fleet-dark`: agterm doesn't document
  # resolving named theme files, only plain ghostty keys in this file.
  home.file.".config/agterm/ghostty.conf".text = lib.concatStringsSep "\n" (
    (map (p: "palette = ${p}") theme.palette)
    ++ lib.mapAttrsToList (k: v: "${k} = ${v}") (removeAttrs theme [ "palette" ])
  );
}
