{
  config,
  osConfig ? null,
  lib,
  ...
}:

let
  cfg = config.theorem.home.base.distrobox;

  podmanEnabled = (osConfig.theorem.nixos.virtualisation.podman.enable or false);

  persistenceEnabled = (config.theorem.home.base.persistence.enable or false);
in
{
  options.theorem.home.base.distrobox.enable = lib.mkEnableOption "Distrobox";

  config = lib.mkIf podmanEnabled {
    services.podman.enable = true;

    home.persistence."/nix/persist" = lib.mkIf persistenceEnabled {
      directories = [
        ".local/share/containers"
      ];
    };

    programs.distrobox = lib.mkIf cfg.enable {
      enable = true;
    };
  };
}
