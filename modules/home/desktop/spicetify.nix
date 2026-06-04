{
  config,
  inputs,
  lib,
  ...
}:
# Spicetify wires the Spotify customization substrate while leaving extension
# selection to user profiles. This keeps the shared module mechanical and avoids
# making one listener's taste part of the base desktop.
let
  cfg = config.theorem.home.desktop.spicetify;
in
{
  options.theorem.home.desktop.spicetify = {
    enable = lib.mkEnableOption "Spicetify";

    enabledExtensions = lib.mkOption {
      type = lib.types.listOf lib.types.anything;
      default = [ ];
      description = ''
        Spicetify extensions enabled for Spotify. Extension choice is user
        workflow; the reusable module only wires the mechanism.
      '';
    };

    persistConfig = lib.mkOption {
      type = lib.types.bool;
      default = config.theorem.home.base.persistence.enable;
      defaultText = lib.literalExpression "theorem.home.base.persistence.enable";
      description = "Persist Spotify configuration when Home persistence is active.";
    };
  };

  imports = [ inputs.spicetify-nix.homeManagerModules.spicetify ];

  config = lib.mkIf cfg.enable {
    programs.spicetify = {
      enable = true;

      enabledExtensions = cfg.enabledExtensions;
    };

    home.persistence."/nix/persist" = lib.mkIf cfg.persistConfig {
      directories = [
        ".config/spotify"
      ];
    };
  };
}
