{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.desktop.spicetify;

  # Default mechanism, kept in the reusable module; home/ may override it.
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  options.theorem.home.desktop.spicetify.enable = lib.mkEnableOption "Spicetify";

  imports = [ inputs.spicetify-nix.homeManagerModules.spicetify ];

  config = lib.mkIf cfg.enable {
    programs.spicetify = {
      enable = true;

      enabledExtensions = with spicePkgs.extensions; [
        adblockify
        hidePodcasts
        shuffle
      ];
    };

    home.persistence."/nix/persist" = lib.mkIf config.theorem.home.base.persistence.enable {
      directories = [
        ".config/spotify"
      ];
    };
  };
}
