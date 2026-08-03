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
  # The dead-man switch lives here rather than on the node: an exit node is the
  # least trusted machine in the system, and a provider token on it would trade a
  # runaway bill for a compromised account.
  age.secrets = {
    nomad-vultr = {
      file = ../../secrets/nomad-vultr.age;
      path = "${secretsDir}/nomad-vultr";
    };
    nomad-digitalocean = {
      file = ../../secrets/nomad-digitalocean.age;
      path = "${secretsDir}/nomad-digitalocean";
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
