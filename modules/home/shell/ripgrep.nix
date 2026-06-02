{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.shell.ripgrep;
in
{
  options.theorem.home.shell.ripgrep.enable = lib.mkEnableOption "ripgrep";

  config = lib.mkIf cfg.enable {
    programs.ripgrep = {
      enable = true;

      arguments = [
        "--hidden"
        "--smart-case"
        "--max-columns=200"
        "--max-columns-preview"

        "--glob=!.git/"
        "--glob=!result"
        "--glob=!result-*"
        "--glob=!.direnv/"
        "--glob=!.devenv/"

        "--colors=line:style:bold"
      ];
    };
  };
}
