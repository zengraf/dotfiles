{ pkgs, self }:
let
  mkNuApp = pkgs.callPackage ./mk-nu-app { };
  callPackage = pkgs.lib.callPackageWith (pkgs // { inherit mkNuApp self; });
in
{
  inherit mkNuApp;

  packages = {
    cache-push = callPackage ./cache-push { };
    # Shadows nixpkgs' HashiCorp Nomad inside the overlay.
    nomad = callPackage ./nomad { };
  };

  checks = {
    mk-nu-app = mkNuApp {
      pname = "mk-nu-app-fixture";
      src = ./mk-nu-app/fixture;
      bins.hello = "hello.nu";
      substitutions.true = "${pkgs.coreutils}/bin/true";
      tests = [ "test.nu" ];
    };
  };
}
