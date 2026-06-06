{
  config,
  lib,
  pkgs,
  repository,
  selectedUsers,
  ...
}:
# Podman substrate for rootless containers and Docker-shaped compatibility.
# Rootless use does not need a standing group grant; the `podman` group is added
# only when the Docker-compatible socket is enabled, because that socket is an
# engine-control surface and should follow repository stewardship.
let
  cfg = config.theorem.nixos.virtualisation.podman;
  repositoryGroup = repository.group or "nixcfg";

  isRepositoryUser =
    _name: user:
    (user.group or null) == repositoryGroup || lib.elem repositoryGroup (user.extraGroups or [ ]);

  # The Docker-compatible Podman socket is an engine-control surface. Upstream
  # gates it with the `podman` group, so grant that key only to repository
  # stewards unless a host deliberately widens access elsewhere.
  podmanSocketUsers = lib.attrNames (lib.filterAttrs isRepositoryUser selectedUsers);

  podmanRootlessUsers = lib.filterAttrs isRepositoryUser selectedUsers;

  mkSubUidRange = user: {
    startUid = 100000 + ((user.uid - 1000) * 65536);
    count = 65536;
  };

  mkSubGidRange = user: {
    startGid = 100000 + ((user.uid - 1000) * 65536);
    count = 65536;
  };
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
        tools can ask the container engine to do. When enabled, selected
        repository stewards receive the `podman` group required to connect;
        enable it only for a named workflow that needs socket access.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    security.shadow.enable = lib.mkDefault true;

    virtualisation = {
      containers.enable = true;
      podman = {
        enable = true;
        autoPrune.enable = true;
        dockerCompat = cfg.dockerCompat.enable;
        dockerSocket.enable = cfg.dockerSocket.enable;
        defaultNetwork.settings.dns_enabled = cfg.composeDns.enable;
        extraPackages = lib.mkIf cfg.composeDns.enable [
          pkgs.podman-compose
        ];
      };
    };

    users.users = lib.mkMerge [
      (lib.mapAttrs (_: user: {
        subUidRanges = lib.mkDefault [ (mkSubUidRange user) ];
        subGidRanges = lib.mkDefault [ (mkSubGidRange user) ];
      }) podmanRootlessUsers)

      (lib.mkIf cfg.dockerSocket.enable (
        lib.genAttrs podmanSocketUsers (_: {
          extraGroups = lib.mkAfter [ "podman" ];
        })
      ))
    ];
  };
}
