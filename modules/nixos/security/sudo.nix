{
  config,
  lib,
  ...
}:
let
  cfg = config.vicky.nixos.security.sudo;

  swBin = "/run/current-system/sw/bin";
  wrappersBin = "/run/wrappers/bin";
in
{
  options.vicky.nixos.security.sudo.enable = lib.mkEnableOption "Sudo with good defaults";

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
