{
  osConfig ? null,
  ...
}:

let
  # The V Rising server is a single-machine role, not a hardware capability, so
  # it is chosen by host identity rather than by a `theorem.nixos.*` flag. Only
  # one host may own the world saves at a time; two hosts running the same
  # `saveName` would be two divergent worlds, not a shared one.
  # ponytail: a hostname literal beats a new NixOS option for a single role.
  # Promote to `theorem.nixos.gaming.vrising.enable` if a second role-bearing
  # service needs the same treatment.
  vrisingHost = "saturnine";
  isVrisingHost = osConfig != null && osConfig.networking.hostName == vrisingHost;
in
{
  theorem.home.gaming = {
    nwn.enable = true;
    vrising = {
      enable = isVrisingHost;
      serverName = "VickyKillin's World";
      saveName = "world1";
      maxUsers = 8;
      public = true;
      # Empty preset so the server reads the migrated ServerGameSettings.json
      # (the single-player rules) instead of a canned preset.
      preset = "";

      # Twice daily, and only when nobody is on and the world is freshly
      # saved. Confirm `playerCountCommand` against a running server: until
      # it parses a count, every firing skips.
      maintenance.enable = true;
    };
    lutris.enable = true;
    mangohud = {
      enable = true;
      # settings = {

      # };
    };
  };
}
