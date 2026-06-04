{
  config,
  lib,
  ...
}:
# Traditional sudo elevation profile for hosts that have not moved to run0.
# The profile keeps wheel as the administrative boundary and grants passwordless
# power and mount operations for local repair. Do not enable it beside
# `theorem.nixos.security.run0-sudo`; the run0 module owns that exclusion.
let
  cfg = config.theorem.nixos.security.sudo;

  swBin = "/run/current-system/sw/bin";
  wrappersBin = "/run/wrappers/bin";
in
{
  options.theorem.nixos.security.sudo.enable = lib.mkEnableOption "Sudo with good defaults";

  config = lib.mkIf cfg.enable {
    security.sudo = {
      enable = true;

      extraRules = [
        {
          groups = [ "wheel" ];
          commands = [
            # We're using the name of the symlink in the final system image instead of, for
            # example `"${pkgs.systemd}/bin/shutdown"`, because in the final system it is the symlink
            # that will be invoked and sudo matches against the invoked command and not the resolved
            # binary
            {
              command = "${swBin}/shutdown";
              options = [ "NOPASSWD" ];
            }
            {
              command = "${swBin}/reboot";
              options = [ "NOPASSWD" ];
            }
            {
              command = "${swBin}/poweroff";
              options = [ "NOPASSWD" ];
            }
            {
              command = "${wrappersBin}/mount";
              options = [ "NOPASSWD" ];
            }
            {
              command = "${wrappersBin}/umount";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];
      extraConfig = # sh
        ''
          Defaults pwfeedback # Make typed password visible as asterisks
        '';
    };
  };
}
