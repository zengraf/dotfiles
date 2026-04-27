{
  lib,
  pkgs,
  inputs,
  username,
  hostname,
  agenix,
  ...
}:
{
  users.users.${username}.shell = pkgs.nushell;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    extraSpecialArgs = { inherit inputs username hostname agenix; };
    sharedModules = [ inputs.nix-index-database.homeModules.default ];
  };
}
