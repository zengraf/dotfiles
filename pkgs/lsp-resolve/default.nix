{
  mkNuApp,
  devenv,
}:
mkNuApp {
  pname = "lsp-resolve";
  src = ./.;
  bins = {
    lsp-resolve = "lsp-resolve.nu";
    npm-policy = "npm-policy.nu";
  };
  substitutions = {
    devenv = "${devenv}/bin/devenv";
  };
  tests = [ "test.nu" ];
  meta = {
    description = "Start a language server from the project, its devenv, or a pinned fallback";
    mainProgram = "lsp-resolve";
  };
}
