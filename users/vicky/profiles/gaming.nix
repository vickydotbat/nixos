{
  config,
  lib,
  pkgs,
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

      # RCON exists so the idle-restart guard can ask whether anyone is on.
      # The port stays unpublished (`rconPublish` defaults false), so this is
      # reachable only through `podman exec` on this host. It is world-readable
      # in the Nix store, which is acceptable for something nothing outside the
      # container can connect to; publishing the port would change that.
      rconPassword = "wch3wLeDyve5Lv61uvsG";

      # Twice daily, and only when nobody is on and the world is freshly saved.
      maintenance.enable = true;
    };
    lutris.enable = true;
    mangohud = {
      enable = true;
      # settings = {

      # };
    };
  };

  # Thunderstore mod manager, on both hosts. It is a client-side tool: it
  # installs BepInEx and mods into a Steam game directory
  # (~/.local/share/Steam/steamapps/common/VRising) and knows nothing about the
  # dedicated server container. Server mods are a separate job.
  # ponytail: a package plus its state directory, no module. Promote to
  # `theorem.home.gaming.r2modman` if a second user ever needs it.
  home.packages = [ pkgs.r2modman ];

  # Profiles, downloaded mods and the manager's own settings all live here.
  # The game directory itself is persisted by modules/home/gaming/steam.nix.
  home.persistence."/nix/persist" = lib.mkIf config.theorem.home.base.persistence.enable {
    directories = [ ".config/r2modmanPlus-local" ];
  };
}
