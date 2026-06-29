final: prev:
prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
  openconnect = prev.openconnect.overrideAttrs (o: {
    configureFlags = (o.configureFlags or [ ]) ++ [
      "--with-external-browser=${final.writeShellScript "openconnect-external-browser" ''exec /usr/bin/open "$@"''}"
    ];
  });
}
