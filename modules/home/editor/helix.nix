{
  config,
  lib,
  ...
}:
let
  cfg = config.theorem.home.editor.helix;
in
{
  options.theorem.home.editor.helix = {
    enable = lib.mkEnableOption "Helix editor";

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = ''
        Helix settings installed by the shared editor theorem. Keep this sparse
        in the reusable layer; themes, keybindings, and editing temperament
        belong in user modules.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.helix = {
      enable = true;
      settings = cfg.settings;
    };
  };
}
