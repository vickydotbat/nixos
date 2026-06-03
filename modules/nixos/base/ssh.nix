{ config, lib, ... }:
let
  cfg = config.theorem.nixos.base.ssh;
in
{
  options.theorem.nixos.base.ssh = {
    enable = lib.mkEnableOption "base OpenSSH configuration";

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Open the firewall for OpenSSH. Keep this explicit on hosts where SSH is
        only needed over a private overlay or during a narrow maintenance rite.
      '';
    };

    startAgent = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Start the system SSH agent program. Disable this when user or desktop
        configuration owns agent lifetime instead.
      '';
    };
  };

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

      openFirewall = cfg.openFirewall;
    };

    programs.ssh.startAgent = cfg.startAgent;
  };
}
