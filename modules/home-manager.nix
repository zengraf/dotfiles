{
  lib,
  pkgs,
  inputs,
  username,
  hostname,
  ...
}:
{
  users.users.${username}.shell = lib.mkDefault pkgs.nushell;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    extraSpecialArgs = { inherit inputs username hostname; };
    sharedModules = [ inputs.nix-index-database.homeModules.default ];
  };
}
