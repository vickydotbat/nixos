{ ... }:

{
  networking.hostName = "solanine";

  # V Rising dedicated server (theorem.home.gaming.vrising, a rootless Podman
  # container in vicky's session). Ports must match the module's gamePort and
  # queryPort; the query port is always gamePort + 1. RCON stays closed.
  networking.firewall.allowedUDPPorts = [
    9876
    9877
  ];

  # Keep vicky's user systemd instance alive with no session open, so the
  # server keeps running after logout and starts again at boot.
  users.users.vicky.linger = true;

  system.stateVersion = "25.11";
}
