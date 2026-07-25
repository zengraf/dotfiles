final: prev:
let
  py = final.python3Packages;

  # nixpkgs' mk-python-derivation.nix conditionally adds pythonMetadataCheckHook
  # for pyproject packages whose version does NOT contain "unstable-".
  # The tree-sitter grammars have versions like "0+unstable20260411" or "1.0.3"
  # which don't trigger the exclusion, but their upstream PyPI dist-info doesn't
  # match nixpkgs naming (python-tree-sitter-* vs tree_sitter_*).
  # Append "-unstable-" to the version string to trigger the built-in skip.
  skipMetaCheck = pkg: pkg.overridePythonAttrs (old: {
    pythonRemoveDeps = old.pythonRemoveDeps or [ ];
    version = old.version + "-unstable-";
  });

  ts-grammars = builtins.mapAttrs (_: skipMetaCheck) py.tree-sitter-grammars;

  graphify-pkg = py.buildPythonPackage rec {
    pname = "graphifyy";
    version = "0.8.49";
    pyproject = true;

    src = py.fetchPypi {
      inherit pname version;
      hash = "sha256-u//X2m4OnsPp7bQPMuDHvBGf9tt9y9W7mgrZp9XTuoc=";
    };

    build-system = [ py.setuptools ];

    # nixpkgs ships one coherent tree-sitter grammar set; graphify pins tight
    # upper bounds we don't want to fight at build time.
    pythonRelaxDeps = true;

    dependencies = [
      py.networkx
      py.numpy
      py.rapidfuzz
      py.tree-sitter
    ]
    ++ (with ts-grammars; [
      tree-sitter-objc
      tree-sitter-python
      tree-sitter-javascript
      tree-sitter-typescript
      tree-sitter-go
      tree-sitter-rust
      tree-sitter-java
      tree-sitter-groovy
      tree-sitter-c
      tree-sitter-cpp
      tree-sitter-ruby
      tree-sitter-c-sharp
      tree-sitter-kotlin
      tree-sitter-scala
      tree-sitter-php
      tree-sitter-swift
      tree-sitter-lua
      tree-sitter-zig
      tree-sitter-powershell
      tree-sitter-elixir
      tree-sitter-julia
      tree-sitter-verilog
      tree-sitter-fortran
      tree-sitter-bash
      tree-sitter-json
    ]);

    pythonImportsCheck = [ "graphify" ];

    meta = {
      description = "Turn any folder of code, docs, papers, images, or videos into a queryable knowledge graph";
      homepage = "https://github.com/safishamsi/graphify";
      license = final.lib.licenses.mit;
      mainProgram = "graphify";
    };
  };

  graphify-env = final.python3.withPackages (_: [ graphify-pkg ]);

  graphify-skill = final.runCommand "graphify-skill-${graphify-pkg.version}" { } ''
    export HOME="$(mktemp -d)"
    export CLAUDE_CONFIG_DIR="$out"
    ${graphify-env}/bin/graphify install --platform claude
  '';
in
{
  graphify = graphify-env;
  inherit graphify-skill;
}
