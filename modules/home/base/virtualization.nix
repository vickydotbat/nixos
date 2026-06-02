{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.base.virtualization;
in
{
  options.theorem.home.base.virtualization.enable = lib.mkEnableOption "user virtualization tools";

  config = lib.mkIf cfg.enable {
    programs.distrobox = {
      enable = true;
    };

    services.podman = {
      enable = true;
    };

    home.persistence."/nix/persist" = lib.mkIf config.theorem.home.base.persistence.enable {
      directories = [
        ".local/share/containers"
      ];
    };
  };
}
