final: prev: {
  qemu_kvm =
    if prev.stdenv.hostPlatform.isDarwin then
      prev.qemu_kvm.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ../patches/qemu/0001-hvf-sme-assert.patch ];
      })
    else
      prev.qemu_kvm;
}
