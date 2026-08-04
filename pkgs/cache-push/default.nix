{
  lib,
  stdenvNoCC,
  makeWrapper,
  nushell,
  age,
  age-plugin-se,
}:
let
  cache = import ../../cache.nix;
in
stdenvNoCC.mkDerivation {
  pname = "cache-push";
  version = "0.1.0";

  src = lib.cleanSource ./.;

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  doCheck = true;
  checkPhase = ''
    runHook preCheck
    ${lib.getExe nushell} -c "nu-check --debug cache-push.nu"
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/cache-push
    cp cache-push.nu $out/share/cache-push/

    makeWrapper ${lib.getExe nushell} $out/bin/cache-push \
      --add-flags $out/share/cache-push/cache-push.nu \
      --set CACHE_SECRETS ${../../secrets} \
      --set CACHE_PUBLIC_KEY ${lib.escapeShellArg cache.publicKey} \
      --set CACHE_UPSTREAM ${lib.escapeShellArg cache.upstream} \
      --prefix PATH : ${
        lib.makeBinPath [
          age
          age-plugin-se
        ]
      }

    runHook postInstall
  '';

  meta = {
    description = "Sign and push this flake's closures to the private cache";
    mainProgram = "cache-push";
    platforms = lib.platforms.darwin;
  };
}
