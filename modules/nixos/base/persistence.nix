{
  config,
  lib,
  pkgs,
  ...
}:
# Btrfs impermanence substrate. `/nix` and selected state live on durable Btrfs
# subvolumes while `/` is rolled back to a blank snapshot every boot.
#
# In systemd initrd, before `/` is mounted, the rollback service replaces
# `root.btrfsSubvolume` with a fresh copy of `root.btrfsBlankSubvolume`. The
# blank snapshot must be created once at install time, before the root subvolume
# accumulates mutable state.
#
# Swap is host-owned because size and placement depend on storage layout. Home
# persistence is owned by Home Manager modules; this module only prepares
# `/nix/persist/home/<user>` for users that declare persisted Home state.
let
  cfg = config.theorem.nixos.base.persistence;

  btrfsOptions = subvolume: [
    "subvol=${subvolume}"
    "compress=${cfg.storage.btrfsCompression}"
  ];

  btrfsRollbackMountPoint = "/mnt-btrfs-root";
  btrfsRollbackScript = ''
    set -eu

    mount_point=${lib.escapeShellArg btrfsRollbackMountPoint}
    device=${lib.escapeShellArg cfg.storage.device}
    root_subvolume=${lib.escapeShellArg cfg.root.btrfsSubvolume}
    blank_subvolume=${lib.escapeShellArg cfg.root.btrfsBlankSubvolume}

    ${pkgs.coreutils}/bin/mkdir -p "$mount_point"

    cleanup() {
      ${pkgs.util-linux}/bin/umount "$mount_point" 2>/dev/null || true
    }
    trap cleanup EXIT

    ${pkgs.util-linux}/bin/mount -t btrfs -o ${lib.escapeShellArg "subvol=${cfg.root.btrfsTopLevelSubvolume}"} "$device" "$mount_point"

    if ! ${pkgs.btrfs-progs}/bin/btrfs subvolume show "$mount_point/$blank_subvolume" >/dev/null 2>&1; then
      echo "Missing Btrfs blank root snapshot: $blank_subvolume" >&2
      exit 1
    fi

    if [ -e "$mount_point/$root_subvolume" ]; then
      if ! ${pkgs.btrfs-progs}/bin/btrfs subvolume show "$mount_point/$root_subvolume" >/dev/null 2>&1; then
        echo "Refusing to replace non-subvolume root path: $root_subvolume" >&2
        exit 1
      fi

      ${pkgs.btrfs-progs}/bin/btrfs subvolume list -o "$mount_point/$root_subvolume" \
        | ${pkgs.gnused}/bin/sed 's/.* path //' \
        | ${pkgs.coreutils}/bin/sort -r \
        | while IFS= read -r nested_subvolume; do
            if [ -n "$nested_subvolume" ]; then
              ${pkgs.btrfs-progs}/bin/btrfs subvolume delete "$mount_point/$nested_subvolume"
            fi
          done

      ${pkgs.btrfs-progs}/bin/btrfs subvolume delete "$mount_point/$root_subvolume"
    fi

    ${pkgs.btrfs-progs}/bin/btrfs subvolume snapshot "$mount_point/$blank_subvolume" "$mount_point/$root_subvolume"
  '';

  mkHomePersistDir =
    _: homeConfig:
    let
      user = homeConfig.home.username;
      group = config.users.users.${user}.group;
    in
    "d /nix/persist/home/${user} 0700 ${user} ${group} -";

  homeUsers = config.home-manager.users or { };

  homeUsersWithPersistedKnownHosts = lib.filterAttrs (
    _: homeConfig:
    let
      knownHostsFile = homeConfig.theorem.home.base.ssh.knownHostsFile or "";
    in
    homeConfig.theorem.home.base.ssh.enable or false && lib.hasPrefix "/nix/persist/" knownHostsFile
  ) homeUsers;

  mkPersistedKnownHosts =
    _: homeConfig:
    let
      user = homeConfig.home.username;
      group = config.users.users.${user}.group;
      persistedKnownHosts = homeConfig.theorem.home.base.ssh.knownHostsFile;
      persistedKnownHostsDir = builtins.dirOf persistedKnownHosts;
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
  options.theorem.nixos.base.persistence = {
    enable = lib.mkEnableOption "system persistence for impermanence";

    storage = {
      manageFileSystems = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Let this module declare `/`, `/boot`, and `/nix`. Disable it when a
          host imports disko or another storage authority that already generates
          those mounts; persistence and rollback policy stay active either way.
        '';
      };

      device = lib.mkOption {
        type = lib.types.str;
        default = "/dev/disk/by-label/ROOT";
        description = "Btrfs device carrying the root, `/nix`, and persistence subvolumes.";
      };

      btrfsCompression = lib.mkOption {
        type = lib.types.str;
        default = "zstd:1";
        description = "Compression option applied to Btrfs subvolumes.";
      };
    };

    root = {
      btrfsSubvolume = lib.mkOption {
        type = lib.types.str;
        default = "@root";
        description = "Btrfs subvolume mounted at `/`.";
      };

      btrfsBlankSubvolume = lib.mkOption {
        type = lib.types.str;
        default = "@root-blank";
        description = ''
          Read-only Btrfs snapshot the root subvolume is recreated from during
          initrd rollback. Create it once after installation, while the root
          subvolume is still empty.
        '';
      };

      btrfsTopLevelSubvolume = lib.mkOption {
        type = lib.types.str;
        default = "/";
        description = ''
          Btrfs subvolume mounted in initrd so the rollback service can see both
          `root.btrfsSubvolume` and `root.btrfsBlankSubvolume`.
        '';
      };
    };

    boot = {
      device = lib.mkOption {
        type = lib.types.str;
        default = "/dev/disk/by-label/EFI";
        description = "EFI system partition mounted at `/boot`.";
      };

      fsType = lib.mkOption {
        type = lib.types.str;
        default = "vfat";
        description = "Filesystem type for `/boot`.";
      };

      mountOptions = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "fmask=0077"
          "dmask=0077"
          "defaults"
        ];
        description = "Mount options for `/boot`.";
      };
    };

    nix.subvolume = lib.mkOption {
      type = lib.types.str;
      default = "@nix";
      description = "Btrfs subvolume mounted at `/nix`.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.initrd.systemd = {
      enable = true;

      # The rollback script calls these by absolute store path. systemd-initrd
      # ships the unit-script but not its runtime closure, so force the full
      # tools in (the initrd otherwise only carries util-linux-minimal).
      storePaths = [
        pkgs.util-linux
        pkgs.btrfs-progs
        pkgs.gnused
        pkgs.coreutils
      ];

      services.rollback-root = {
        description = "Roll back Btrfs root to blank snapshot";
        wantedBy = [ "initrd.target" ];
        # Order after the root block device exists (udev settled, LUKS opened)
        # and before `/` is mounted. `before` + `wantedBy initrd.target` is the
        # canonical impermanence wiring; a hard `requiredBy = sysroot.mount`
        # couples the mount to this unit in a way the proven recipes avoid.
        after = [ "initrd-root-device.target" ];
        before = [ "sysroot.mount" ];
        unitConfig.DefaultDependencies = "no";
        serviceConfig.Type = "oneshot";
        script = btrfsRollbackScript;
      };
    };

    fileSystems = lib.mkIf cfg.storage.manageFileSystems {
      "/" = {
        device = cfg.storage.device;
        fsType = "btrfs";
        options = btrfsOptions cfg.root.btrfsSubvolume;
      };

      "/boot" = {
        device = cfg.boot.device;
        fsType = cfg.boot.fsType;
        options = cfg.boot.mountOptions;
      };

      "/nix" = {
        device = cfg.storage.device;
        fsType = "btrfs";
        options = btrfsOptions cfg.nix.subvolume;
        neededForBoot = true;
      };
    };

    boot.tmp.cleanOnBoot = true;

    environment.persistence."/nix/persist" = {
      hideMounts = true;

      directories = [
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

    systemd.tmpfiles.rules = lib.mapAttrsToList mkHomePersistDir homeUsers;

    system.activationScripts.persistedKnownHosts = {
      deps = [ "createPersistentStorageDirs" ];
      text = lib.concatStringsSep "\n" (
        lib.mapAttrsToList mkPersistedKnownHosts homeUsersWithPersistedKnownHosts
      );
    };

    system.activationScripts.persist-files.deps = [ "persistedKnownHosts" ];

    services.journald.extraConfig = ''
      SystemMaxUse=512M
      SystemKeepFree=1G
      RuntimeMaxUse=128M
      MaxFileSec=1week
    '';
  };
}
