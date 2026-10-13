{
  lib,
  stdenvNoCC,
  nushell,
}:
{
  pname,
  version ? "0.1.0",
  src,
  bins,
  # placeholder name -> store path; every @name@ in src becomes the path
  substitutions ? { },
  # std assert scripts, relative to src; they run from the source root
  tests ? [ ],
  meta ? { },
}:
let
  nu = lib.getExe nushell;
  share = "$out/share/${pname}";
  # Nu resolves `use` against the path it was given, which is the bin/ symlink.
  flags = "--no-config-file --no-std-lib --include-path ${share}";
in
stdenvNoCC.mkDerivation {
  inherit pname version src;

  # patchShebangs rewrites /usr/bin/env to the store coreutils env.
  dontPatchShebangs = true;

  buildPhase = ''
    runHook preBuild
    ${lib.concatStrings (
      lib.mapAttrsToList (name: path: ''
        files=$(grep -rlF -- ${lib.escapeShellArg "@${name}@"} . || true)
        if [ -z "$files" ]; then
          echo "mkNuApp: placeholder @${name}@ appears in no file" >&2
          exit 1
        fi
        for f in $files; do
          substituteInPlace "$f" --replace-fail ${lib.escapeShellArg "@${name}@"} ${lib.escapeShellArg path}
        done
      '') substitutions
    )}
    ${lib.concatStrings (
      lib.mapAttrsToList (_: script: ''
        { echo "#!/usr/bin/env -S ${nu} ${flags}"; cat ${lib.escapeShellArg script}; } > entry.tmp
        mv entry.tmp ${lib.escapeShellArg script}
      '') bins
    )}
    runHook postBuild
  '';

  doCheck = true;
  checkPhase = ''
    runHook preCheck
    export HOME=$TMPDIR
    find . -name '*.nu' -print0 | while IFS= read -r -d "" f; do
      ${nu} --no-config-file -c "if not (nu-check --debug '$f') { exit 1 }"
    done
    ${lib.concatMapStrings (t: ''
      ${nu} --no-config-file ${lib.escapeShellArg t}
    '') tests}
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin ${share}
    cp -r . ${share}
    ${lib.concatMapStrings (t: ''
      rm ${share}/${lib.escapeShellArg t}
    '') tests}
    ${lib.concatStrings (
      lib.mapAttrsToList (bin: script: ''
        chmod +x ${share}/${lib.escapeShellArg script}
        ln -s ${share}/${lib.escapeShellArg script} $out/bin/${lib.escapeShellArg bin}
      '') bins
    )}
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    ${lib.concatMapStrings (bin: ''
      (cd / && ${nu} ${flags} $out/bin/${lib.escapeShellArg bin} --help > /dev/null)
    '') (lib.attrNames bins)}
    runHook postInstallCheck
  '';

  meta = {
    platforms = lib.platforms.darwin ++ lib.platforms.linux;
  }
  // lib.optionalAttrs (lib.length (lib.attrNames bins) == 1) {
    mainProgram = lib.head (lib.attrNames bins);
  }
  // meta;
}
