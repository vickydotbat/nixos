{
  pkgs,
  lib,
  config,
  ...
}:
{
  home.packages = with pkgs; [ sillytavern ];

  home.persistence."/nix/persist" = lib.mkIf config.theorem.home.base.persistence.enable {
    directories = [
      ".local/share/SillyTavern"
    ];
  };
}
