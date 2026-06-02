{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.shell.codex;
in
{
  options.theorem.home.shell.codex.enable = lib.mkEnableOption "Codex CLI";

  config = lib.mkIf cfg.enable {
    home.packages = [
      inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
