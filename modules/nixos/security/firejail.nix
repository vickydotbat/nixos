{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.nixos.security.firejail;
in
{
  options.theorem.nixos.security.firejail = {
    enable = lib.mkEnableOption "Firejail sandboxing";

    installCli = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install the firejail CLI for debugging and manual testing.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.firejail.enable = true;

    environment.systemPackages = lib.optionals cfg.installCli [
      pkgs.firejail
    ];
  };
}
