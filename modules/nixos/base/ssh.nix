{ config, lib, ... }:
# TODO: SSH needs hardening. SSH should also be disabled by default. Also, how is it populating systemwide SSH keys? If this is disabled, those keys should cease to exist on the system. Make sure any systemwide ssh key evaluation is done here, where able.
let
  cfg = config.theorem.nixos.base.ssh;
in
{
  options.theorem.nixos.base.ssh.enable = lib.mkEnableOption "base OpenSSH configuration";

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;

      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        X11Forwarding = false;
        UseDns = false;
      };

      openFirewall = true;
    };

    programs.ssh.startAgent = true;
  };
}
