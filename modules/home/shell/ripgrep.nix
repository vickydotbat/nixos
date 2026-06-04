{
  config,
  lib,
  ...
}:
# ripgrep is the shared search tool. The reusable module keeps default arguments
# conservative; repository-specific hidden-file habits and noisy excludes belong
# in the user or project layer.
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
