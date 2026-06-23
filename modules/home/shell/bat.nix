{
  config,
  lib,
  pkgs,
  ...
}:
# `bat` is a shell readability tool with optional Bash integration. The module
# installs useful extras and pager defaults while keeping aliases tied to the
# shell theorem that will actually consume them.
let
  cfg = config.theorem.home.shell.bat;
in
{
  options.theorem.home.shell.bat = {
    enable = lib.mkEnableOption "bat";

    bashIntegration.enable = lib.mkOption {
      type = lib.types.bool;
      default = config.theorem.home.shell.shell.enable or true;
      defaultText = lib.literalExpression "theorem.home.shell.shell.enable";
      description = "Export bat pager defaults into Bash when the shell theorem is active.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      programs.bat = {
        enable = true;
        config = {
          italic-text = "always";
          pager = "less -FR";
          style = "numbers,changes,header";
          theme = "TwoDark";
        };
        extraPackages = with pkgs.bat-extras; [
          batdiff
          batgrep
          batman
          batwatch
        ];
      };

      programs.bash = lib.mkIf cfg.bashIntegration.enable {

        sessionVariables = {
          BAT_PAGER = "less -FR";
          MANPAGER = "sh -c 'col -bx | bat -l man -p'";
        };

        shellAliases = {
          cat = "bat --paging=never --style=plain";
          bat = "bat --paging=never";
        };
      };
    })
  ];
}
