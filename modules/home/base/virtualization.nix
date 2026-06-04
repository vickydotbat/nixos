{
  config,
  osConfig ? null,
  lib,
  options,
  ...
}:
# Home-side Distrobox integration. It activates only when the surrounding NixOS
# system provides Podman containers, so a standalone Home flake can import this
# module without accidentally depending on unavailable system services.
let
  cfg = config.theorem.home.base.distrobox;

  podmanEnabled =
    osConfig != null
    && (osConfig.virtualisation.containers.enable or false)
    && (osConfig.virtualisation.podman.enable or false);

  persistenceEnabled = (config.theorem.home.base.persistence.enable or false);
  hasHomePersistence = options.home ? persistence;
in
{
  options.theorem.home.base.distrobox = {
    enable = lib.mkEnableOption "Distrobox";

    persistContainers = lib.mkOption {
      type = lib.types.bool;
      default = persistenceEnabled;
      defaultText = lib.literalExpression "theorem.home.base.persistence.enable";
      description = ''
        Persist rootless container state for Distrobox. Disable when containers
        should be disposable crucibles rather than kept user state.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && podmanEnabled) {
      services.podman.enable = true;

      programs.distrobox = {
        enable = true;
      };
    })
    (lib.optionalAttrs hasHomePersistence {
      home.persistence."/nix/persist" = lib.mkIf (cfg.enable && podmanEnabled && cfg.persistContainers) {
        directories = [
          ".local/share/containers"
        ];
      };
    })
  ];
}
