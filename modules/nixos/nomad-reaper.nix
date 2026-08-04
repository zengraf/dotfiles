{
  lib,
  pkgs,
  self,
  ...
}:
let
  nomad = self.packages.${pkgs.stdenv.hostPlatform.system}.nomad;
  secretsDir = "/run/nomad-secrets";
in
{
  # Not on the node itself: an exit node is public-facing, and a provider token
  # there would trade a runaway bill for a compromised account.
  #
  # Conditional so the repo evaluates while a backend is still unprovisioned.
  age.secrets =
    lib.optionalAttrs (builtins.pathExists ../../secrets/nomad/vultr.age) {
      nomad-vultr = {
        file = ../../secrets/nomad/vultr.age;
        path = "${secretsDir}/vultr";
      };
    }
    // lib.optionalAttrs (builtins.pathExists ../../secrets/nomad/digitalocean.age) {
      nomad-digitalocean = {
        file = ../../secrets/nomad/digitalocean.age;
        path = "${secretsDir}/digitalocean";
      };
    };

  systemd.services.nomad-reaper = {
    description = "Destroy expired ephemeral exit nodes";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${lib.getExe nomad} reap";
      Environment = [ "NOMAD_SECRETS_PLAIN=${secretsDir}" ];
    };
  };

  systemd.timers.nomad-reaper = {
    description = "Reap expired ephemeral exit nodes";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "5min";
      Persistent = true;
    };
  };
}
