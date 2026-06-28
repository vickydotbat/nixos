{
  pkgs,
  lib,
  config,
  ...
}:
{
  home.packages = with pkgs; [
    sillytavern
    libreoffice
  ];

  home.persistence."/nix/persist" = lib.mkIf config.theorem.home.base.persistence.enable {
    directories = [
      ".local/share/SillyTavern"
    ];
  };
}
