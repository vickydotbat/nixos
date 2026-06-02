{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.base.ssh;

  # Default mechanism, kept in the reusable module; home/ may override it.
  sshDir = "${config.home.homeDirectory}/.ssh";
  sshPrivateKeySecret = "/run/secrets/ssh-vicky-id_ed25519";
  sshPublicKeySecret = "/run/secrets/ssh-vicky-id_ed25519.pub";
in
{
  options.theorem.home.base.ssh.enable = lib.mkEnableOption "SSH client configuration";

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      settings = {
        "*" = {
          IdentityFile = "~/.ssh/id_ed25519";
          SetEnv = {
            TERM = "xterm-256color";
          };
          AddKeysToAgent = "yes";
        };

        "github.com" = {
          User = "git";
          IdentityFile = "~/.ssh/id_ed25519";
          IdentitiesOnly = true;
        };

        "ovh_sow" = {
          User = "ubuntu";
          Port = 50340;
          HostName = "51.254.142.98";
          IdentityFile = "~/.ssh/id_ed25519";
        };

        "git-ssh.westgate.pw" = {
          HostName = "git-ssh.westgate.pw";
          Port = 2222;
          User = "git";
          IdentityFile = "~/.ssh/id_ed25519";
          IdentitiesOnly = true;
        };
      };
    };

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
