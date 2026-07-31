{
  networking.hostName = "saturnine";

  # V Rising dedicated server (theorem.home.gaming.vrising, a rootless Podman
  # container in vicky's session). Ports must match the module's gamePort and
  # queryPort; the query port is always gamePort + 1. RCON stays closed.
  # Without these, clients cannot reach the host directly and fall back to the
  # EOS relay, which adds latency and drops connections.
  networking.firewall.allowedUDPPorts = [
    9876
    9877
  ];

  # Keep vicky's user systemd instance alive with no session open, so the
  # server keeps running after logout and starts again at boot.
  users.users.vicky.linger = true;

  # This host serves the world over WiFi. Power save parks the radio between
  # beacons, which shows up in game as latency spikes and lost packets.
  networking.networkmanager.wifi.powersave = false;

  system.stateVersion = "26.05";
}
