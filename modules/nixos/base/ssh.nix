{
  config,
  lib,
  pkgs,
  ...
}:
# Base OpenSSH server posture. This owns inbound `sshd` only; user SSH client
# identities live in Home Manager so Git signing and outbound access do not
# imply that the host accepts remote logins.
let
  cfg = config.theorem.nixos.base.ssh;
  userAccounts = config.theorem.nixos.base.users.accounts or { };
  accountsWithRuntimeAuthorizedKeys = lib.filterAttrs (
    _: account: account.enable && (account.sshAuthorizedKeyFiles or [ ]) != [ ]
  ) userAccounts;
  hasRuntimeAuthorizedKeys = accountsWithRuntimeAuthorizedKeys != { };

  mkAuthorizedKeysScript =
    name: account:
    let
      target = "/run/ssh-authorized-keys/${name}";
      keyFiles = account.sshAuthorizedKeyFiles or [ ];
    in
    ''
      target=${lib.escapeShellArg target}
      tmp="$(mktemp)"

      for key_file in ${lib.escapeShellArgs keyFiles}; do
        if [[ -r "$key_file" ]]; then
          cat "$key_file" >> "$tmp"
          printf '\n' >> "$tmp"
        fi
      done

      if [[ -s "$tmp" ]]; then
        install -m 0644 "$tmp" "$target"
      else
        rm -f "$target"
      fi

      rm -f "$tmp"
    '';
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

      settings = {
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

    services.openssh.authorizedKeysFiles = lib.mkIf hasRuntimeAuthorizedKeys (
      lib.mkAfter [ "/run/ssh-authorized-keys/%u" ]
    );

    systemd.services.ssh-authorized-keys = lib.mkIf hasRuntimeAuthorizedKeys {
      description = "Assemble runtime OpenSSH authorized keys from SOPS public-key material";
      wantedBy = [ "multi-user.target" ];
      wants = [ "sops-nix.service" ];
      after = [ "sops-nix.service" ];
      before = [ "sshd.service" ];
      path = with pkgs; [
        coreutils
      ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        install -d -m 0755 /run/ssh-authorized-keys
        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList mkAuthorizedKeysScript accountsWithRuntimeAuthorizedKeys
        )}
      '';
    };
  };
}
