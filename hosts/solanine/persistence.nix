{ config, lib, pkgs, ... }:

let
  mkHomePersistDir =
    _: homeConfig:
    let
      user = homeConfig.home.username;
      group = config.users.users.${user}.group;
    in
    "d /nix/persist/home/${user} 0700 ${user} ${group} -";

  homeUsersWithKnownHosts =
    lib.filterAttrs
      (
        _: homeConfig:
        lib.any
          (
            persistence:
            lib.any (file: file.file == ".ssh/known_hosts") (persistence.files or [ ])
          )
          (lib.attrValues (homeConfig.home.persistence or { }))
      )
      config.home-manager.users;

  mkPersistedKnownHosts =
    _: homeConfig:
    let
      user = homeConfig.home.username;
      group = config.users.users.${user}.group;
      persistedKnownHostsDir = "/nix/persist/home/${user}/.ssh";
      persistedKnownHosts = "${persistedKnownHostsDir}/known_hosts";
    in
    ''
      ${pkgs.coreutils}/bin/install -d -m 0700 -o ${user} -g ${group} ${lib.escapeShellArg persistedKnownHostsDir}
      if [[ ! -e ${lib.escapeShellArg persistedKnownHosts} ]]; then
        ${pkgs.coreutils}/bin/touch ${lib.escapeShellArg persistedKnownHosts}
      fi
      ${pkgs.coreutils}/bin/chown ${user}:${group} ${lib.escapeShellArg persistedKnownHosts}
      ${pkgs.coreutils}/bin/chmod 0600 ${lib.escapeShellArg persistedKnownHosts}
    '';
in
{
  fileSystems."/nix".neededForBoot = true;

  boot.tmp.cleanOnBoot = true;

  systemd.tmpfiles.rules = lib.mapAttrsToList mkHomePersistDir config.home-manager.users;

  system.activationScripts.persistedKnownHosts = {
    deps = [ "createPersistentStorageDirs" ];
    text = lib.concatStringsSep "\n" (
      lib.mapAttrsToList mkPersistedKnownHosts homeUsersWithKnownHosts
    );
  };

  system.activationScripts.persist-files.deps = [ "persistedKnownHosts" ];

  environment.persistence."/nix/persist" = {
    hideMounts = true;

    directories = [
      {
        directory = "/tmp";
        mode = "1777";
      }
      { directory = "/etc/NetworkManager/system-connections"; }
      { directory = "/var/lib/nixos"; }
      { directory = "/var/lib/bluetooth"; }
      { directory = "/var/log"; }
      { directory = "/var/lib/systemd/timers"; }
      { directory = "/var/lib/systemd/coredump"; }
      { directory = "/var/tmp"; }
    ];

    files = [
      "/etc/machine-id"
    ];
  };
}
