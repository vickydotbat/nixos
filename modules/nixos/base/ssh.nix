{ config, lib, ... }:

let
  cfg = config.vicky.nixos.base.ssh;
in
{
  options.vicky.nixos.base.ssh.enable = lib.mkEnableOption "base OpenSSH configuration";

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
