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
# Enrolment is a manual rite by default. Run `run0 tailscale up` once after the
# first rebuild and complete the login in a browser.
#
# A host that must come back without a keyboard can point `authKey.sopsFile` at
# an encrypted key instead, and the daemon enrols itself on first boot. What
# that trades away: the key is a standing credential that can add machines to
# the tailnet, where the browser login is spent the moment it is used. Prefer an
# OAuth client secret (`tskey-client-…`) over a plain auth key, because it does
# not expire after 90 days and its `--advertise-tags` confine what it can join
# as.
let
  cfg = config.theorem.nixos.base.tailscale;
  authKeySecretName = "tailscale-authkey";
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

    authKey = {
      sopsFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          SOPS file holding a `tailscale-authkey` entry, whose plaintext is the
          bare key and nothing else. When set, the daemon enrols itself
          on first boot and nobody has to sit at the machine. Leave it null to
          keep enrolment a one-time browser login.
        '';
      };

      tags = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "tag:server" ];
        description = ''
          Tags to claim while enrolling, as `--advertise-tags`. An OAuth client
          secret requires at least one tag that its grant allows; a plain auth
          key does not need any.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;

      authKeyFile = lib.mkIf (cfg.authKey.sopsFile != null) config.sops.secrets.${authKeySecretName}.path;

      extraUpFlags = lib.mkIf (cfg.authKey.tags != [ ]) [
        "--advertise-tags=${lib.concatStringsSep "," cfg.authKey.tags}"
      ];
    };

    sops.secrets = lib.mkIf (cfg.authKey.sopsFile != null) {
      ${authKeySecretName} = {
        sopsFile = cfg.authKey.sopsFile;
        key = authKeySecretName;
        owner = "root";
        group = "root";
        mode = "0400";
      };
    };

    networking.firewall.trustedInterfaces = lib.mkIf cfg.trustInterface [ "tailscale0" ];

    environment.persistence."/nix/persist" = lib.mkIf config.theorem.nixos.base.persistence.enable {
      hideMounts = true;
      directories = [ "/var/lib/tailscale" ];
    };
  };
}
