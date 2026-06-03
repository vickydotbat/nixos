{ config, lib, ... }:
# TODO: Flatpak needs hardening.
let
  cfg = config.theorem.nixos.desktop.flatpak;
in
{
  options.theorem.nixos.desktop.flatpak.enable = lib.mkEnableOption "Flatpak usability";

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;

    environment.persistence."/nix/persist" = lib.mkIf config.theorem.nixos.base.persistence.enable {
      hideMounts = true;
      directories = [ "/var/lib/flatpak" ];
    };
  };
}
