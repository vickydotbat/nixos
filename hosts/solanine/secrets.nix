{
  config,
  lib,
  selectedUsers,
  ...
}:
let
  hostSecretsFile = ../../secrets/solanine.yaml;

  hasHostSecretKey =
    key: builtins.pathExists hostSecretsFile && lib.hasInfix key (builtins.readFile hostSecretsFile);

  userHasSshSecretKey =
    user: key:
    builtins.pathExists user.ssh.sopsFile && lib.hasInfix key (builtins.readFile user.ssh.sopsFile);

  usersWithPasswordSecrets = lib.filterAttrs (_: user: user.passwordHashSecret != null) selectedUsers;

  usersWithSshSecrets = lib.filterAttrs (
    _: user: (user.ssh.enable or false) && userHasSshSecretKey user "id_ed25519:"
  ) selectedUsers;

  mkPasswordSecret = _: user: {
    name = user.passwordHashSecret;
    value = {
      neededForUsers = true;
    };
  };

  mkUserSshSecrets = _: user: {
    ${user.ssh.privateKeySecret} = {
      sopsFile = user.ssh.sopsFile;
      path = user.ssh.privateKeyPath;
      owner = user.username;
      group = "users";
      mode = "0600";
    };

    ${user.ssh.publicKeySecret} = {
      sopsFile = user.ssh.sopsFile;
      path = user.ssh.publicKeyPath;
      owner = user.username;
      group = "users";
      mode = "0644";
    };
  };
in
{
  theorem.nixos.security.sops = {
    enable = true;
    defaultSopsFile = hostSecretsFile;
  };

  sops.secrets = {
    firefox-backup-age-identity = {
      owner = "vicky";
      mode = "0400";
    };
  }
  // builtins.listToAttrs (lib.mapAttrsToList mkPasswordSecret usersWithPasswordSecrets)
  //
    lib.optionalAttrs (config.theorem.nixos.base.ssh.enable && hasHostSecretKey "ssh_host_ed25519_key:")
      {
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
  // lib.optionalAttrs config.theorem.nixos.base.ssh.enable (
    lib.foldl' lib.recursiveUpdate { } (lib.mapAttrsToList mkUserSshSecrets usersWithSshSecrets)
  );
}
