{
  config,
  osConfig ? null,
  lib,
  pkgs,
  ...
}:
# TODO: SSH defaults for system-wide need evaluation, but this module should only allow itself to be enabled when systemwide SSH is also enabled. It should however be disabled by default. Likewise it needs per-user configuration. Some users might not use this.
let
  sshEnabled = (osConfig.theorem.nixos.base.ssh.enable or false);
  username = config.home.username;

  # Default mechanism, kept in the reusable module; home/ may override it.
  sshDir = "${config.home.homeDirectory}/.ssh";
  sshPrivateKeySecret = "/run/secrets/ssh-${username}-id_ed25519";
  sshPublicKeySecret = "/run/secrets/ssh-${username}-id_ed25519.pub";
in
{
  # Derived from active SSH state.
  config = lib.mkIf sshEnabled {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = lib.mkDefault false; # Respect per-use mandates in home/users.
    };

    # Spawn SSH Keys from SOPS generation in the /home/user/.ssh directory.
    home.activation.sshDirectory = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -d -m 0700 ${lib.escapeShellArg sshDir}
    '';

    home.activation.sshKeys = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      ssh_dir=${lib.escapeShellArg sshDir}
      private_key_secret=${lib.escapeShellArg sshPrivateKeySecret}
      public_key_secret=${lib.escapeShellArg sshPublicKeySecret}

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
