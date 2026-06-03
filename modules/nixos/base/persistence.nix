{
  config,
  lib,
  pkgs,
  ...
}:
# Impermanence substrate for hosts that keep `/nix` and selected state on
# durable storage while letting `/` return to a clean shape at boot.
#
# The tmpfs root path is ready for daily use. The Btrfs root mode is present so
# hosts can name the desired substrate, but it still needs a rollback-to-blank
# initrd rite before it should be selected on real hardware.

/*
  TODO: Clarify differentials between tmpfs and btrfs.

  For right now I can't see whether it's possible to run /nix on ext4, whether
  /nix defaults to btrfs if ephemeral tmpfs is used... etc. Default for normal
  drives should be btrfs impermanence for everything but this requires special
  setup. BTRFS impermanence bootstrap is not currently explained nor configured.
  In order to set that up, bootstrap requires an empty snapshot to be made upon
  installation of the system, and a script that rolls back to that snapshot on
  each reboot.

  Relevant Example Docs:
   - btrfs impermanence, no tmpfs: <https://cnx.gdn/blog/butter/>
   - btrfs impermanence with tmpfs root:
    - <https://gist.github.com/giuseppe998e/629774863b149521e2efa855f7042418>
    - <https://news.ycombinator.com/item?id=31269972>
   - tmpfs root with ext4: <https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/>

  For most of my systems currently, I use btrfs by default for all drives except
  for /, which is on tmpfs. Tmpfs root requires the full spread of persistence
  simply to keep directories that get large off ram. Things to consider.
*/
let
  cfg = config.theorem.nixos.base.persistence;

  btrfsOptions = subvolume: [
    "subvol=${subvolume}"
    "compress=${cfg.storage.btrfsCompression}"
  ];

  nixMountOptions =
    if cfg.storage.fsType == "btrfs" then btrfsOptions cfg.nix.subvolume else cfg.storage.mountOptions;

  rootMount =
    if cfg.root.mode == "tmpfs" then
      {
        device = "none";
        fsType = "tmpfs";
        options = [
          "defaults"
          "size=${cfg.root.tmpfsSize}"
          "mode=755"
        ];
      }
    else
      {
        device = cfg.storage.device;
        fsType = "btrfs";
        options = btrfsOptions cfg.root.btrfsSubvolume;
      };

  mkHomePersistDir =
    _: homeConfig:
    let
      user = homeConfig.home.username;
      group = config.users.users.${user}.group;
    in
    "d /nix/persist/home/${user} 0700 ${user} ${group} -";

  homeUsers = config.home-manager.users or { };

  homeUsersWithKnownHosts = lib.filterAttrs (
    _: homeConfig:
    lib.any (persistence: lib.any (file: file.file == ".ssh/known_hosts") (persistence.files or [ ])) (
      lib.attrValues (homeConfig.home.persistence or { })
    )
  ) homeUsers;

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
  options.theorem.nixos.base.persistence = {
    enable = lib.mkEnableOption "system persistence for impermanence";

    storage = {
      fsType = lib.mkOption {
        type = lib.types.str;
        default = "btrfs";
        description = ''
          Filesystem model used by persistent system storage. `/nix` follows
          this value so the host has one storage doctrine instead of mixed
          accidental formats.
        '';
      };

      device = lib.mkOption {
        type = lib.types.str;
        default = "/dev/disk/by-label/ROOT";
        description = "Persistent storage device for `/nix` and disk-backed roots.";
      };

      mountOptions = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "defaults" ];
        description = "Mount options used for non-Btrfs persistent storage.";
      };

      btrfsCompression = lib.mkOption {
        type = lib.types.str;
        default = "zstd:1";
        description = "Compression option used for Btrfs persistent subvolumes.";
      };
    };

    root = {
      mode = lib.mkOption {
        type = lib.types.enum [
          "tmpfs"
          "btrfs"
        ];
        default = "tmpfs";
        description = ''
          Impermanent root substrate. `tmpfs` starts clean naturally; `btrfs`
          requires a rollback-to-blank mechanism before it should be used on a
          real host.
        '';
      };

      tmpfsSize = lib.mkOption {
        type = lib.types.str;
        default = "25%";
        description = "Size limit for a tmpfs root.";
      };

      btrfsSubvolume = lib.mkOption {
        type = lib.types.str;
        default = "@root";
        description = "Btrfs subvolume mounted at `/` when root mode is `btrfs`.";
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
      description = "Btrfs subvolume mounted at `/nix` when persistent storage is Btrfs.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.root.mode != "btrfs" || cfg.storage.fsType == "btrfs";
        message = ''
          theorem.nixos.base.persistence.root.mode = "btrfs" requires
          theorem.nixos.base.persistence.storage.fsType = "btrfs". Impermanent
          disk-backed roots are Btrfs rollback systems here; ext4 belongs under
          persistent `/nix`, not `/`.
        '';
      }
    ];

    fileSystems."/" = rootMount;

    fileSystems."/boot" = {
      device = cfg.boot.device;
      fsType = cfg.boot.fsType;
      options = cfg.boot.mountOptions;
    };

    fileSystems."/nix" = {
      device = cfg.storage.device;
      fsType = cfg.storage.fsType;
      options = nixMountOptions;
      neededForBoot = true;
    };

    boot.tmp.cleanOnBoot = true;

    environment.persistence."/nix/persist" = {
      hideMounts = true;

      directories = [
        {
          directory = "/tmp"; # Cleaned on boot.
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

    systemd.tmpfiles.rules = lib.mapAttrsToList mkHomePersistDir homeUsers;

    system.activationScripts.persistedKnownHosts = {
      deps = [ "createPersistentStorageDirs" ];
      text = lib.concatStringsSep "\n" (lib.mapAttrsToList mkPersistedKnownHosts homeUsersWithKnownHosts);
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
