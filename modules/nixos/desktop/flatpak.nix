{ config, lib, ... }:

let
  cfg = config.vicky.nixos.desktop.flatpak;
in
{
  options.vicky.nixos.desktop.flatpak.enable = lib.mkEnableOption "Flatpak usability";

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;

    environment.persistence."/nix/persist" = {
      hideMounts = true;
      directories = ["/var/lib/flatpak"];
    };
  };
}
