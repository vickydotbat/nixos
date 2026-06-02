{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.desktop.discord;
in
{
  options.theorem.home.desktop.discord.enable = lib.mkEnableOption "Discord";

  config = lib.mkIf cfg.enable {
    programs.discord.enable = true;
    services.arrpc.enable = true;

    home.persistence."/nix/persist" = lib.mkIf config.theorem.home.base.persistence.enable {
      directories = [
        ".config/discord"
      ];
    };

    xdg.configFile."autostart/discord.desktop".text = ''
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
  };
}
