{ pkgs, ... }:
{
  programs.discord.enable = true;
  services.arrpc.enable = true;

  home.persistence."/nix/persist" = {
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
}
