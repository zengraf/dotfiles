{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  active = "/etc/nix/machines.active";

  orDash = xs: if xs == [ ] then "-" else lib.concatStringsSep "," xs;
  line =
    m:
    lib.concatStringsSep " " [
      "${m.protocol}://${lib.optionalString (m.sshUser != null) "${m.sshUser}@"}${m.hostName}"
      (orDash m.systems)
      (if m.sshKey != null then m.sshKey else "-")
      (toString m.maxJobs)
      (toString m.speedFactor)
      (orDash (m.supportedFeatures ++ m.mandatoryFeatures))
      (orDash m.mandatoryFeatures)
      (if m.publicHostKey != null then m.publicHostKey else "-")
    ];

  # A machine with a mandatory feature never takes a plain x86_64-linux build, so it keeps
  # the system.
  withoutX86 =
    m:
    if m.mandatoryFeatures != [ ] then
      m
    else
      m // { systems = lib.remove "x86_64-linux" m.systems; };

  # No ssh key: Tailscale SSH authenticates the node, and the daemon runs as root with no
  # key of its own.
  mainframe = "ssh-ng://${username}@mainframe x86_64-linux - 20 1 benchmark,big-parallel,kvm,nixos-test - c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUhBYmhTT0pXZGg4UHRudzNHMXRiR0RVdlN2ZGxCUGVPdGF5LzZtaTJBeW4K";

  builder = pkgs.writeShellScriptBin "builder" ''
    case "''${1-}" in
      mainframe) sudo ln -sfn /etc/nix/machines.mainframe ${active} ;;
      virby) sudo ln -sfn /etc/nix/machines ${active} ;;
      "") ;;
      *) echo "usage: builder [mainframe|virby]" >&2; exit 2 ;;
    esac
    readlink ${active}
  '';
in
{
  environment.etc."nix/machines.mainframe".text = lib.concatLines (
    map line (lib.filter (m: m.systems != [ ]) (map withoutX86 config.nix.buildMachines))
    ++ [ mainframe ]
  );

  nix.settings.builders = "@${active}";

  environment.systemPackages = [ builder ];

  system.activationScripts.extraActivation.text = ''
    if [[ ! -L ${active} ]]; then
      ln -s /etc/nix/machines.mainframe ${active}
    fi
  '';
}
