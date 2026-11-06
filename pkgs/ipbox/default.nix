{ mkNuApp }:
mkNuApp {
  pname = "ipbox";
  src = ./.;
  bins.ipbox-fetch = "ipbox-fetch.nu";
  tests = [ "test.nu" ];
  meta.description = "Fetch a month of merged PRs with patches as IP Box evidence";
}
