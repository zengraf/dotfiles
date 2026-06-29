final: prev:
prev.lib.optionalAttrs (prev.stdenv.hostPlatform.isDarwin && prev.stdenv.hostPlatform.isAarch64) (
  let
    py = prev.python313Packages;
    fw = url: sha256: prev.fetchurl { inherit url sha256; };
    wheels = [
      (fw "https://files.pythonhosted.org/packages/ee/0b/dc76c463c203e630b2c6417d4d5e337e919a265ac1c10127ef413551f5de/pyqt6_sip-13.11.1-cp313-cp313-macosx_10_13_universal2.whl" "0c6d097aae7df312519e2b36e001bd796f6a2ce060ab8b9ed793daa8f407fe2e")
      (fw "https://files.pythonhosted.org/packages/09/7d/d016af2de1975a0d90c9a911e3d82b2e8c8fe899f8af746ade42186f3845/pyqt6_qt6-6.11.1-py3-none-macosx_11_0_arm64.whl" "fd05b31a3c83111b6eb82bb472ccfe531ef823f70d085b82fd1edc5ad2553c54")
      (fw "https://files.pythonhosted.org/packages/33/44/fcd3dd3f64c83c96bf9bce76ec16cca64bd9b91702c3d08fd8e3dafc73d9/pyqt6-6.11.0-cp310-abi3-macosx_10_14_universal2.whl" "f7100bc7f72b12581ec479a733f4ad11b8002668e6786e8a445ab6f4d1c743d4")
      (fw "https://files.pythonhosted.org/packages/18/c4/24a856ec9efb97fb75062cebc64f4a8e7c55125a838ab71f163e268c08b2/pyqt6_webengine_qt6-6.11.1-py3-none-macosx_11_0_arm64.whl" "766ad691fb274eb1ed222eee407d6c16b398a06782441f4a2ad7dd699aa9392a")
      (fw "https://files.pythonhosted.org/packages/28/55/d06c4c1390268ca19a5be6e00e9b394b7bed995ace51b8f10ac19e8770c7/pyqt6_webengine-6.11.0-cp310-abi3-macosx_10_14_universal2.whl" "dfd6efc1760a8f0a82a41366f44dd1949380be5b7e62ca79165ef67ae6f26456")
    ];
    pyqt6Site = prev.runCommand "pyqt6-webengine-wheels-6.11" { nativeBuildInputs = [ prev.unzip ]; } ''
      mkdir -p $out
      for w in ${toString wheels}; do unzip -qo -d $out "$w"; done
    '';
  in
  {
    openconnect-sso = py.buildPythonApplication {
      pname = "openconnect-sso";
      version = "0.8.2";
      pyproject = true;

      src = prev.fetchFromGitHub {
        owner = "PrestonHager";
        repo = "openconnect-sso";
        rev = "36d093fa06730688baed6b4d130e5ec6ce026507";
        sha256 = "08zy09z3hv2drgskq9a1zwrjgi90fj4x0xrq8yhschbx66nbnl26";
      };

      build-system = [ py.setuptools ];

      dontCheckRuntimeDeps = true;
      pythonImportsCheck = [ ];

      dependencies = with py; [
        attrs
        colorama
        lxml
        keyring
        prompt-toolkit
        pyxdg
        requests
        structlog
        toml
        setuptools
        pysocks
        pyotp
      ];

      makeWrapperArgs = [
        "--prefix PYTHONPATH : ${pyqt6Site}"
        "--prefix PATH : ${final.openconnect}/bin"
      ];

      meta = {
        description = "OpenConnect wrapper with SAML/SSO (Azure AD) browser auth for Cisco AnyConnect VPNs";
        homepage = "https://github.com/PrestonHager/openconnect-sso";
        license = prev.lib.licenses.gpl3Only;
        mainProgram = "openconnect-sso";
        platforms = prev.lib.platforms.darwin;
      };
    };
  }
)
