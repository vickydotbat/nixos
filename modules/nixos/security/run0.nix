{
  config,
  lib,
  ...
}:

let
  cfg = config.theorem.nixos.security.run0-sudo;
in
{
  options.theorem.nixos.security.run0-sudo.enable = lib.mkEnableOption "Run0 instead of sudo";

  config = lib.mkIf cfg.enable {
    security.sudo.enable = false;
    security.polkit.enable = true;
    security.run0 = {
      enable = true;
      enableSudoAlias = true;
    };
  };
}
