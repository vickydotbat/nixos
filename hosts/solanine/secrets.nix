{ lib, ... }:

let
  hostSecretsFile = ../../secrets/solanine.yaml;
  userSshSecretsFile = ../../secrets/ssh-vicky.yaml;

  hasHostSecretKey =
    key: builtins.pathExists hostSecretsFile && lib.hasInfix key (builtins.readFile hostSecretsFile);

  hasUserSshSecretKey =
    key:
    builtins.pathExists userSshSecretsFile && lib.hasInfix key (builtins.readFile userSshSecretsFile);
in
{
  theorem.nixos.security.sops = {
    enable = true;
    defaultSopsFile = hostSecretsFile;
  };

  theorem.nixos.base.users = {
    rootPasswordHashFile = "/run/secrets-for-users/users/root/password-hash";
    primaryUserPasswordHashFile = "/run/secrets-for-users/users/vicky/password-hash";
  };

  sops.secrets = {
    firefox-backup-age-identity = {
      owner = "vicky";
      mode = "0400";
    };

    "users/root/password-hash" = {
      neededForUsers = true;
    };

    "users/vicky/password-hash" = {
      neededForUsers = true;
    };
  }
  // lib.optionalAttrs (hasHostSecretKey "ssh_host_ed25519_key:") {
    "ssh/host/ssh_host_ed25519_key" = {
      path = "/etc/ssh/ssh_host_ed25519_key";
      owner = "root";
      group = "root";
      mode = "0600";
    };

    "ssh/host/ssh_host_ed25519_key.pub" = {
      path = "/etc/ssh/ssh_host_ed25519_key.pub";
      owner = "root";
      group = "root";
      mode = "0644";
    };

    "ssh/host/ssh_host_rsa_key" = {
      path = "/etc/ssh/ssh_host_rsa_key";
      owner = "root";
      group = "root";
      mode = "0600";
    };

    "ssh/host/ssh_host_rsa_key.pub" = {
      path = "/etc/ssh/ssh_host_rsa_key.pub";
      owner = "root";
      group = "root";
      mode = "0644";
    };
  }
  // lib.optionalAttrs (hasUserSshSecretKey "id_ed25519:") {
    "ssh/vicky/id_ed25519" = {
      sopsFile = userSshSecretsFile;
      path = "/run/secrets/ssh-vicky-id_ed25519";
      owner = "vicky";
      group = "users";
      mode = "0600";
    };

    "ssh/vicky/id_ed25519.pub" = {
      sopsFile = userSshSecretsFile;
      path = "/run/secrets/ssh-vicky-id_ed25519.pub";
      owner = "vicky";
      group = "users";
      mode = "0644";
    };
  };
}
