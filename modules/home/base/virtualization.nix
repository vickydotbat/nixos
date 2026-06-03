{
  config,
  osConfig ? null,
  lib,
  ...
}:
let
  cfg = config.theorem.home.base.distrobox;

  podmanEnabled =
    (osConfig.virtualisation.containers.enable or false)
    && (osConfig.virtualisation.podman.enable or false);

  persistenceEnabled = (config.theorem.home.base.persistence.enable or false);
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

  config = lib.mkIf (cfg.enable && podmanEnabled) {
    services.podman.enable = true;

    home.persistence."/nix/persist" = lib.mkIf cfg.persistContainers {
      directories = [
        ".local/share/containers"
      ];
    };

    programs.distrobox = {
      enable = true;
    };
  };
}
