{
  lib,
  self,
  stdenvNoCC,
  makeWrapper,
  nushell,
  age,
  age-plugin-se,
  rclone,
}:
stdenvNoCC.mkDerivation {
  pname = "nomad";
  version = "0.1.0";

  src = lib.cleanSource ./.;

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  # tailscale and nix stay out of the closure: the Mac's tailscale CLI belongs to
  # the desktop app, and nix here is lix. --prefix leaves both on the caller's PATH.
  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/nomad
    cp -r nomad.nu secrets.nu r2.nu backends $out/share/nomad/
    cp -r ${../../secrets} $out/share/nomad/secrets

    makeWrapper ${lib.getExe nushell} $out/bin/nomad \
      --add-flags $out/share/nomad/nomad.nu \
      --set NOMAD_FLAKE ${self} \
      --set NOMAD_SECRETS $out/share/nomad/secrets \
      --prefix PATH : ${
        lib.makeBinPath (
          [
            age
            rclone
          ]
          ++ lib.optional stdenvNoCC.hostPlatform.isDarwin age-plugin-se
        )
      }

    runHook postInstall
  '';

  meta = {
    description = "Ephemeral geo-located Tailscale exit nodes";
    mainProgram = "nomad";
    # Also built for the router, which runs `nomad reap` from a timer.
    platforms = lib.platforms.darwin ++ lib.platforms.linux;
  };
}
