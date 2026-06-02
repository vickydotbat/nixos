{ config, lib, ... }:

let
  cfg = config.theorem.nixos.virtualisation.podman;
in
{
  options.theorem.nixos.virtualisation.podman.enable =
    lib.mkEnableOption "Podman virtualisation stack";

  config = lib.mkIf cfg.enable {
    virtualisation = {
      containers.enable = true;
      podman = {
        enable = true;
        autoPrune.enable = true;

        # Create symlink to have podman impersonate the `docker` command
        dockerCompat = true;

        # Required for containers under podman-compose to be able to talk to each other.
        defaultNetwork.settings.dns_enabled = true;

        # Note that this setting exists, but it is a security risk so it should be enabled only when absolutely
        # necessary, in a developer-like profile (looking at you, skaffold):
        # dockerSocket.enable = true;
      };
    };
  };
}
