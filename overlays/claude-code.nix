final: prev:
{
  # nixpkgs lags each Claude Code release by a few days. The manifest carries
  # the version and the per-platform checksums, so a bump is a refetch of this
  # file and nothing else:
  #   V=$(curl -fsSL https://downloads.claude.ai/claude-code-releases/latest)
  #   curl -fsSL "https://downloads.claude.ai/claude-code-releases/$V/manifest.zst.json" \
  #     -o overlays/claude-code-manifest.json
  claude-code = prev.claude-code.override {
    manifest = final.lib.importJSON ./claude-code-manifest.json;
  };
}
