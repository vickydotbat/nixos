{ config, lib, ... }:
# Flatpak is an explicit desktop compatibility layer. The system installation
# can be persisted, but application permissions and state remain with the app or
# user profile that accepts that sandbox surface.
let
  cfg = config.theorem.nixos.desktop.flatpak;
in
{
  options.theorem.nixos.desktop.flatpak = {
    enable = lib.mkEnableOption "Flatpak usability";

    persistSystemInstallation = lib.mkOption {
      type = lib.types.bool;
      default = config.theorem.nixos.base.persistence.enable;
      defaultText = lib.literalExpression "theorem.nixos.base.persistence.enable";
      description = ''
        Persist the system Flatpak installation under `/nix/persist`. Per-app
        Flatpak permissions are the real hardening surface and should be owned
        by the app or user profile that installs the Flatpak.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;

    environment.persistence."/nix/persist" = lib.mkIf cfg.persistSystemInstallation {
      hideMounts = true;
      directories = [ "/var/lib/flatpak" ];
    };
  };
}
