{ config, lib, ... }:
# Tailscale is the private approach road to this host. It gives the machine a
# stable address inside one operator's tailnet, so `sshd` can be reached from a
# phone or another host without forwarding a port, exposing 22 to the wider
# network, or trusting a public DNS name.
#
# The daemon's state, `/var/lib/tailscale`, holds the node key that proves this
# machine's identity to the tailnet. Under impermanence that directory is wiped
# with the root subvolume every boot, and an unpersisted node re-authenticates
# from zero on each reboot: a new machine in the admin console, a new address,
# and a broken `ssh` target. Persisting it is what makes the address durable.
#
# Enrolment stays a manual rite. Run `run0 tailscale up` once after the first
# rebuild and complete the login in a browser. No auth key is stored here,
# because a long-lived key on disk is a worse secret than a one-time login.
let
  cfg = config.theorem.nixos.base.tailscale;
in
{
  options.theorem.nixos.base.tailscale = {
    enable = lib.mkEnableOption "Tailscale mesh networking";

    trustInterface = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Treat `tailscale0` as a trusted firewall interface, so services already
        listening on the host answer over the tailnet without opening their
        ports to every other network the machine sits on. Turn this off when a
        host should join the tailnet for outbound reach only and must not accept
        inbound tailnet connections.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale.enable = true;

    networking.firewall.trustedInterfaces = lib.mkIf cfg.trustInterface [ "tailscale0" ];

    environment.persistence."/nix/persist" =
      lib.mkIf config.theorem.nixos.base.persistence.enable
        {
          hideMounts = true;
          directories = [ "/var/lib/tailscale" ];
        };
  };
}
