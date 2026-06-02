{ config, lib, ... }:

let
  cfg = config.theorem.nixos.desktop.flatpak;
in
{
  options.theorem.nixos.desktop.flatpak.enable = lib.mkEnableOption "Flatpak usability";

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;

    environment.persistence."/nix/persist" = {
      hideMounts = true;
      directories = [ "/var/lib/flatpak" ];
    };
  };
}
