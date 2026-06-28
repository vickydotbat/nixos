{
  config,
  lib,
  selectedUsers,
  userRegistry,
  ...
}:
let
  hostSecretsFile = ../../secrets/hosts-solanine.yaml;

  hasHostSecretKey =
    key: builtins.pathExists hostSecretsFile && lib.hasInfix key (builtins.readFile hostSecretsFile);

  userHasSshSecretKey =
    user: key:
    builtins.pathExists user.ssh.sopsFile && lib.hasInfix key (builtins.readFile user.ssh.sopsFile);

  userHasAccountSecretKey =
    user: key:
    (user.secrets.sopsFile or null) != null
    && builtins.pathExists user.secrets.sopsFile
    && lib.hasInfix key (builtins.readFile user.secrets.sopsFile);

  usersWithPasswordSecrets = lib.filterAttrs (_: user: user.passwordHashSecret != null) selectedUsers;

  usersWithSshSecrets = lib.filterAttrs (
    _: user: (user.ssh.enable or false) && userHasSshSecretKey user "id_ed25519:"
  ) selectedUsers;

  authorizedSshUserNames = lib.unique (
    lib.concatMap (user: user.ssh.authorizedUsers or [ ]) (lib.attrValues selectedUsers)
  );

  usersWithAuthorizedSshPublicKeys = lib.filterAttrs (
    name: user:
    lib.elem name authorizedSshUserNames
    && (user.ssh.enable or false)
    && userHasSshSecretKey user "id_ed25519.pub:"
  ) userRegistry;

  usersWithFirefoxBackupIdentities = lib.filterAttrs (
    _: user: userHasAccountSecretKey user "firefox-backup-age-identity:"
  ) selectedUsers;

  usersWithHeadroomEnvSecrets = lib.filterAttrs (
    _: user: userHasAccountSecretKey user "headroom-env:"
  ) selectedUsers;

  mkPasswordSecret = _: user: {
    name = user.passwordHashSecret;
    value = {
      neededForUsers = true;
      sopsFile = user.secrets.sopsFile;
    };
  };

  mkFirefoxBackupIdentitySecret = _: user: {
    name = "firefox-backup/${user.username}/age-identity";
    value = {
      sopsFile = user.secrets.sopsFile;
      key = "firefox-backup-age-identity";
      path = "/run/secrets/firefox-backup-${user.username}-age-identity";
      owner = user.username;
      group = "users";
      mode = "0400";
    };
  };

  mkHeadroomEnvSecret = _: user: {
    name = "headroom/${user.username}/env";
    value = {
      sopsFile = user.secrets.sopsFile;
      key = "headroom-env";
      path = "/run/secrets/headroom-${user.username}-env";
      owner = user.username;
      group = "users";
      mode = "0400";
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

  mkUserSshPublicKeySecret = _: user: {
    ${user.ssh.publicKeySecret} = {
      sopsFile = user.ssh.sopsFile;
      path = user.ssh.publicKeyPath;
      owner = "root";
      group = "root";
      mode = "0644";
    };
  };
in
{
  theorem.nixos.security.sops = {
    enable = true;
    defaultSopsFile = hostSecretsFile;
  };

  sops.secrets =
    { }
    // builtins.listToAttrs (lib.mapAttrsToList mkPasswordSecret usersWithPasswordSecrets)
    // builtins.listToAttrs (
      lib.mapAttrsToList mkFirefoxBackupIdentitySecret usersWithFirefoxBackupIdentities
    )
    // builtins.listToAttrs (lib.mapAttrsToList mkHeadroomEnvSecret usersWithHeadroomEnvSecrets)
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
    // lib.foldl' lib.recursiveUpdate { } (
      lib.mapAttrsToList mkUserSshPublicKeySecret usersWithAuthorizedSshPublicKeys
    )
    // lib.foldl' lib.recursiveUpdate { } (lib.mapAttrsToList mkUserSshSecrets usersWithSshSecrets);
}
