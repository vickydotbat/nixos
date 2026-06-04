{
  config,
  lib,
  options,
  pkgs,
  ...
}:
# Discord is a user application, not a system service. This module owns the Home
# Manager package, optional autostart, and persisted chat state while keeping the
# decision to start it automatically explicit.
let
  cfg = config.theorem.home.desktop.discord;
  hasHomePersistence = options.home ? persistence;
in
{
  options.theorem.home.desktop.discord = {
    enable = lib.mkEnableOption "Discord";

    autostart.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Install a declarative desktop autostart entry for Discord. This is a
        user workflow choice and is mainly useful on impermanent systems where
        the mutable autostart directory is not preserved.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      programs.discord.enable = true;
      services.arrpc.enable = true;

      xdg.configFile."autostart/discord.desktop".text = lib.mkIf cfg.autostart.enable ''
        [Desktop Entry]
        Type=Application
        Name=Discord
        Comment=Start Discord
        Exec=${pkgs.discord}/bin/discord --start-minimized
        Icon=discord
        Terminal=false
        X-GNOME-Autostart-enabled=true
        X-KDE-autostart-after=panel
      '';
    })
    (lib.optionalAttrs hasHomePersistence {
      home.persistence."/nix/persist" =
        lib.mkIf (cfg.enable && config.theorem.home.base.persistence.enable)
          {
            directories = [
              ".config/discord"
            ];
          };
    })
  ];
}
