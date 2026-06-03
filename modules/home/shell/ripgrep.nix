{
  config,
  lib,
  ...
}:

let
  cfg = config.theorem.home.shell.ripgrep;
in
{
  options.theorem.home.shell.ripgrep = {
    enable = lib.mkEnableOption "ripgrep";

    arguments = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "--smart-case"
      ];
      description = ''
        Default ripgrep arguments. Keep global behavior unsurprising; repository
        search habits and hidden-file posture belong in user modules.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ripgrep = {
      enable = true;
      arguments = cfg.arguments;
    };
  };
}
