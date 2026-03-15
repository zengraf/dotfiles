{ ... }: {
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    extraSetFlags = [
      "--advertise-exit-node"
      "--advertise-routes=172.20.0.0/12"
      "--ssh"
    ];
  };
}
