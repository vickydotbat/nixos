{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:

let
  cfg = config.theorem.home.editor.vscode;
in
{
  options.theorem.home.editor.vscode.enable = lib.mkEnableOption "Visual Studio Code";

  config = lib.mkIf cfg.enable (import ../../../home/raw/vicky/features/desktop/vscode.nix args);
}
