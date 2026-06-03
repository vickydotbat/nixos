{ config, lib, ... }:
let
  cfg = config.theorem.nixos.virtualisation.podman;
in
{
  options.theorem.nixos.virtualisation.podman = {
    enable = lib.mkEnableOption "Podman virtualisation stack";

    dockerCompat.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Install the Docker-compatible `docker` command shim for Podman. This is
        useful for tools that still invoke Docker directly, but it should be an
        explicit host choice so the compatibility layer is visible.
      '';
    };

    composeDns.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable DNS on Podman's default network so containers started by
        podman-compose can resolve each other by name. Leave disabled unless
        this host actually runs Compose-shaped workloads.
      '';
    };

    dockerSocket.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Expose the Docker-compatible Podman socket. This broadens what local
        tools can ask the container engine to do; enable it only for a named
        workflow that needs socket access.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation = {
      containers.enable = true;
      podman = {
        enable = true;
        autoPrune.enable = true;
        dockerCompat = cfg.dockerCompat.enable;
        dockerSocket.enable = cfg.dockerSocket.enable;
        defaultNetwork.settings.dns_enabled = cfg.composeDns.enable;
      };
    };
  };
}
