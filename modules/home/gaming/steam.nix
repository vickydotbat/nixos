{
  config,
  lib,
  osConfig ? null,
  ...
}:

let
  steamEnabled = (osConfig.theorem.nixos.gaming.steam.enable or false);
in
{
  config = lib.mkIf steamEnabled {
    home.persistence."/nix/persist" = lib.mkIf config.theorem.home.base.persistence.enable {
      directories = [
        ".local/share/Steam"
      ];
    };
  };
}
