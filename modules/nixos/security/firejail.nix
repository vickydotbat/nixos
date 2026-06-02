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
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.theorem.nixos.desktop.jailwolf.enable;
      defaultText = lib.literalExpression "theorem.nixos.desktop.jailwolf.enable";
      description = "Enable Firejail sandboxing when a Firejail-backed desktop theorem needs it.";
    };

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
