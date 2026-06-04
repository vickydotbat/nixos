{
  config,
  lib,
  pkgs,
  ...
}:
# Restores a user's outbound SSH identity from runtime secret material. This is
# deliberately separate from the system OpenSSH server: Git signing and client
# authentication should not require the host to expose `sshd`.
let
  cfg = config.theorem.home.base.ssh;
  username = config.home.username;
  persistenceEnabled = config.theorem.home.base.persistence.enable or false;

  # Default mechanism, kept in the reusable module; user profiles may override it.
  sshDir = "${config.home.homeDirectory}/.ssh";
  persistedSshDir = "/nix/persist/home/${username}/.ssh";
  sshPrivateKeySecret = "/run/secrets/ssh-${username}-id_ed25519";
  sshPublicKeySecret = "/run/secrets/ssh-${username}-id_ed25519.pub";
  knownHostsFile =
    if persistenceEnabled then "${persistedSshDir}/known_hosts" else "${sshDir}/known_hosts";
in
{
  options.theorem.home.base.ssh = {
    enable = lib.mkEnableOption "per-user SSH configuration";

    privateKeySecret = lib.mkOption {
      type = lib.types.str;
      default = sshPrivateKeySecret;
      defaultText = lib.literalExpression ''"/run/secrets/ssh-$${config.home.username}-id_ed25519"'';
      description = "Readable secret path for this user's private SSH key.";
    };

    publicKeySecret = lib.mkOption {
      type = lib.types.str;
      default = sshPublicKeySecret;
      defaultText = lib.literalExpression ''"/run/secrets/ssh-$${config.home.username}-id_ed25519.pub"'';
      description = "Readable secret path for this user's public SSH key.";
    };

    knownHostsFile = lib.mkOption {
      type = lib.types.str;
      default = knownHostsFile;
      defaultText = lib.literalExpression ''
        if theorem.home.base.persistence.enable
        then "/nix/persist/home/$${config.home.username}/.ssh/known_hosts"
        else "$${config.home.homeDirectory}/.ssh/known_hosts"
      '';
      description = ''
        Outbound SSH known-host ledger. Impermanent homes point OpenSSH at the
        persisted file directly, rather than bind-mounting a single file into
        `~/.ssh`, so OpenSSH can rotate `known_hosts.old` on the same
        filesystem when a host key changes.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = lib.mkDefault false; # Respect per-user mandates in users/.
      settings."*".UserKnownHostsFile = lib.mkDefault cfg.knownHostsFile;
    };

    # Restore per-user SSH keys from SOPS material into the user's own profile.
    # This is an outbound identity and Git-signing mechanism; it does not imply
    # that the host runs an OpenSSH server.
    home.activation.sshDirectory = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -d -m 0700 ${lib.escapeShellArg sshDir}
    '';

    home.activation.sshKeys = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      ssh_dir=${lib.escapeShellArg sshDir}
      private_key_secret=${lib.escapeShellArg cfg.privateKeySecret}
      public_key_secret=${lib.escapeShellArg cfg.publicKeySecret}

      $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -d -m 0700 "$ssh_dir"

      if [[ -r "$private_key_secret" ]]; then
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 0600 "$private_key_secret" "$ssh_dir/id_ed25519"
      fi

      if [[ -r "$public_key_secret" ]]; then
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 0644 "$public_key_secret" "$ssh_dir/id_ed25519.pub"
      fi
    '';
  };
}
