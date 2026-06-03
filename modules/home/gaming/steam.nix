{
  config,
  lib,
  osConfig ? null,
  ...
}:

let
  steamEnabled = (osConfig.theorem.nixos.gaming.steam.enable or false);

  persistenceEnabled = (config.theorem.home.base.persistence.enable or false);
in
{
  config = lib.mkIf steamEnabled {
    home.persistence."/nix/persist" = lib.mkIf persistenceEnabled {
      directories = [
        ".local/share/Steam"
      ];
    };
  };
}
