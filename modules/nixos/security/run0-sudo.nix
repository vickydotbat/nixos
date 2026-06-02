{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.nixos.security.run0-sudo;
in
{
  options.theorem.nixos.security.run0-sudo.enable = lib.mkEnableOption "Run0 as sudo";

  config = lib.mkIf cfg.enable {
    security.sudo.enable = false;
    security.polkit.enable = true;

    environment.systemPackages = [
      pkgs.run0-sudo-shim
    ];

    # Preserve an alias for usability
    programs.bash.shellAliases = {
      asroot = "run0";
    };
  };
}
