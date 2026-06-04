{ config, lib, ... }:
# Base OpenSSH server posture. This owns inbound `sshd` only; user SSH client
# identities live in Home Manager so Git signing and outbound access do not
# imply that the host accepts remote logins.
let
  cfg = config.theorem.nixos.base.ssh;
in
{
  options.theorem.nixos.base.ssh = {
    enable = lib.mkEnableOption "base OpenSSH configuration";

    hardenServer = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Apply conservative OpenSSH server hardening. The defaults keep remote
        access key-only, reduce unauthenticated guessing, turn off forwarding
        surfaces, and increase useful authentication logs. Host-specific
        allow-lists, tunnels, and host key declarations still belong on the
        host that needs them.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;

      settings =
        {
          PasswordAuthentication = lib.mkDefault false;
          KbdInteractiveAuthentication = lib.mkDefault false;
          PermitRootLogin = lib.mkDefault "no";
          X11Forwarding = lib.mkDefault false;
          UseDns = lib.mkDefault false;
        }
        // lib.optionalAttrs cfg.hardenServer {
          PermitEmptyPasswords = lib.mkDefault false;
          PermitTunnel = lib.mkDefault false;
          MaxAuthTries = lib.mkDefault 3;
          MaxSessions = lib.mkDefault 2;
          ClientAliveInterval = lib.mkDefault 300;
          ClientAliveCountMax = lib.mkDefault 0;
          TCPKeepAlive = lib.mkDefault false;
          AllowTcpForwarding = lib.mkDefault false;
          AllowAgentForwarding = lib.mkDefault false;
          LogLevel = lib.mkDefault "VERBOSE";
        };

      openFirewall = lib.mkDefault true;
    };

    programs.ssh.startAgent = lib.mkDefault true;
  };
}
