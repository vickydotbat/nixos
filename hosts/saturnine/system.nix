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

  # The server takes a sleep + lid-switch inhibitor from a user service. Polkit
  # resolves that service's session through vicky's graphical login, so on a
  # boot with nobody logged in there is no session, the "any" rules apply
  # (block-sleep: auth_admin_keep, handle-lid-switch: no) and the inhibitor dies
  # with "requires interactive authentication", taking the server with it.
  # Vicky owns the machine and the server, so grant both outright.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.user == "vicky"
          && (action.id == "org.freedesktop.login1.inhibit-block-sleep"
              || action.id == "org.freedesktop.login1.inhibit-handle-lid-switch")) {
        return polkit.Result.YES;
      }
    });
  '';

  # This host serves the world over WiFi. Power save parks the radio between
  # beacons, which shows up in game as latency spikes and lost packets.
  networking.networkmanager.wifi.powersave = false;

  system.stateVersion = "26.05";
}
