final: prev:
let
  py = final.python3Packages;

  tree-sitter-objc = py.buildPythonPackage rec {
    pname = "tree-sitter-objc";
    version = "3.0.2";
    pyproject = true;

    src = py.fetchPypi {
      pname = "tree_sitter_objc";
      inherit version;
      hash = "sha256-rFWu/opPPqbx2iouBTcqTzcQAAGTTjaoHg+WxMYlKAk=";
    };

    build-system = [ py.setuptools ];
    dependencies = [ py.tree-sitter ];

    pythonImportsCheck = [ "tree_sitter_objc" ];
  };

  graphify-pkg = py.buildPythonPackage rec {
    pname = "graphifyy";
    version = "0.5.3";
    pyproject = true;

    src = py.fetchPypi {
      inherit pname version;
      hash = "sha256-jzRX9KDpUYWVHi2y9Nxu6g0CEfTSWa3q+jGUJoM1E+o=";
    };

    build-system = [ py.setuptools ];

    dependencies =
      [
        py.networkx
        py.tree-sitter
        tree-sitter-objc
      ]
      ++ (with py.tree-sitter-grammars; [
        tree-sitter-python
        tree-sitter-javascript
        tree-sitter-typescript
        tree-sitter-go
        tree-sitter-rust
        tree-sitter-java
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
      ]);

    pythonImportsCheck = [ "graphify" ];

    meta = {
      description = "Turn any folder of code, docs, papers, images, or videos into a queryable knowledge graph";
      homepage = "https://github.com/safishamsi/graphify";
      license = final.lib.licenses.mit;
      mainProgram = "graphify";
    };
  };
in
{
  graphify = final.python3.withPackages (_: [ graphify-pkg ]);
}
