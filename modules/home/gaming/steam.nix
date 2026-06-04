{
  config,
  lib,
  osConfig ? null,
  ...
}:

# Home persistence companion for the system Steam profile. It should do nothing
# in standalone Home flakes unless the surrounding NixOS theorem has selected
# Steam, keeping game state declarations tied to the host that installs Steam.
let
  steamEnabled =
    if osConfig == null then false else osConfig.theorem.nixos.gaming.steam.enable or false;

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
