{ config, lib, ... }:

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
