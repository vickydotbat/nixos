{
  config,
  lib,
  pkgs,
  ...
}:
# Firejail is only the sandbox substrate. Application modules decide which
# binaries are wrapped, because blanket sandboxing makes both breakage and false
# confidence too easy to miss.
let
  cfg = config.theorem.nixos.security.firejail;
in
{
  options.theorem.nixos.security.firejail = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.theorem.nixos.desktop.jailwolf.enable;
      defaultText = lib.literalExpression "theorem.nixos.desktop.jailwolf.enable";
      description = ''
        Enable Firejail sandboxing when a Firejail-backed desktop theorem needs
        it. A future hardened system profile may also select this explicitly;
        optional sandboxed applications should still remain profile choices.
      '';
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
