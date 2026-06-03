{ config, lib, ... }:
let
  cfg = config.theorem.nixos.security.hardening;
in
{
  options.theorem.nixos.security.hardening = {
    enable = lib.mkEnableOption "conservative system hardening profile";

    kernel = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Apply low-risk kernel hardening defaults. This protects the running
          kernel image and forces page table isolation, while leaving sharper
          choices such as module locking behind their own switch.
        '';
      };

      protectKernelImage = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Prevent replacing the running kernel image after boot. This also
          disables hibernation through NixOS' upstream security module; hosts
          that rely on hibernation must turn this off deliberately.
        '';
      };

      forcePageTableIsolation = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Force page table isolation even on CPUs that report themselves safe
          from Meltdown. The cost is workload-dependent, so this remains a
          named hardening choice rather than an invisible base setting.
        '';
      };

      lockKernelModules = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Disable kernel module loading once the system has settled. Keep this
          disabled until the host's filesystems, networking, VPN, containers,
          and hardware drivers have all been tested after boot.
        '';
      };

      allowUnprivilegedUserNamespaces = lib.mkOption {
        type = lib.types.bool;
        default =
          config.theorem.nixos.desktop.flatpak.enable || config.theorem.nixos.virtualisation.podman.enable;
        defaultText = lib.literalExpression ''
          theorem.nixos.desktop.flatpak.enable
          || theorem.nixos.virtualisation.podman.enable
        '';
        description = ''
          Allow unprivileged user namespaces when declared host features need
          them. Flatpak and rootless containers are the common reasons; forcing
          this off globally breaks useful sandboxes while pretending to harden
          the host.
        '';
      };
    };

    coredumps.disable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Disable systemd coredump collection and set login core size limits to
        zero. Crash dumps can hold secrets, messages, keys, and browser state;
        debugging hosts can override this with a specialization.
      '';
    };

    journald = {
      boundLocalLogs = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Bound local journal growth and keep journal upload disabled unless a
          host explicitly declares a remote log sink.
        '';
      };

      systemMaxUse = lib.mkOption {
        type = lib.types.str;
        default = "512M";
        description = "Maximum persistent journal storage used by the hardening profile.";
      };

      runtimeMaxUse = lib.mkOption {
        type = lib.types.str;
        default = "128M";
        description = "Maximum volatile journal storage used by the hardening profile.";
      };
    };

    logrotate.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable logrotate for legacy text logs. Journald is still the primary
        log mechanism; this keeps older log files from becoming quiet disk
        pressure.
      '';
    };

    timeSync.chronyNts = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Replace systemd-timesyncd with Chrony using Network Time Security.
          This protects clock synchronization from unauthenticated network time
          while keeping the sharper service replacement inside the opted-in
          hardening profile.
        '';
      };

      servers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "time.cloudflare.com"
          "sth1.nts.netnod.se"
          "sth2.nts.netnod.se"
        ];
        description = ''
          NTS-capable time servers used by Chrony when the hardening profile
          owns time synchronization. Override this per host if locality,
          firewall policy, or provider trust requires a different time source.
        '';
      };
    };

    dbusBroker.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Use dbus-broker instead of the classic D-Bus daemon. This remains
        opt-in until the desktop, portal, Flatpak, and user-service paths have
        been tested on the host.
      '';
    };

    unusedServices = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Disable common ambient services unless the host explicitly declares a
          need for them. These defaults override upstream desktop convenience
          defaults, but ordinary host configuration still wins when location,
          service discovery, WWAN, or unattended upgrade rites are intentional.
        '';
      };

      disableAvahi = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Default Avahi service discovery off. Enable Avahi explicitly on hosts
          that publish or consume mDNS services, printers, media receivers, or
          other local-discovery mechanisms.
        '';
      };

      disableGeoclue = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Default Geoclue location services off. Enable it explicitly for
          hosts that use automatic timezone, redshift-style location, desktop
          weather, maps, or other location-aware applications.
        '';
      };

      disableModemManager = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Default ModemManager off. Enable it explicitly on WWAN-capable hosts;
          otherwise NetworkManager's convenience default can leave an idle
          hardware-facing daemon in the session.
        '';
      };

      disableAutoUpgrade = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Default unattended system upgrades off. Enable auto-upgrade only on
          hosts with a declared maintenance window, rollback path, and alerting
          plan.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf cfg.kernel.enable {
        security = {
          protectKernelImage = lib.mkDefault cfg.kernel.protectKernelImage;
          forcePageTableIsolation = lib.mkDefault cfg.kernel.forcePageTableIsolation;
          lockKernelModules = lib.mkDefault cfg.kernel.lockKernelModules;
          unprivilegedUsernsClone = lib.mkDefault cfg.kernel.allowUnprivilegedUserNamespaces;
        };
      })

      (lib.mkIf cfg.coredumps.disable {
        systemd.coredump.enable = lib.mkDefault false;

        security.pam.loginLimits = [
          {
            domain = "*";
            type = "-";
            item = "core";
            value = 0;
          }
        ];
      })

      (lib.mkIf cfg.journald.boundLocalLogs {
        services.journald = {
          upload.enable = lib.mkDefault false;
          extraConfig = lib.mkAfter ''
            SystemMaxUse=${cfg.journald.systemMaxUse}
            RuntimeMaxUse=${cfg.journald.runtimeMaxUse}
          '';
        };
      })

      (lib.mkIf cfg.logrotate.enable {
        services.logrotate.enable = lib.mkDefault true;
      })

      (lib.mkIf cfg.timeSync.chronyNts.enable {
        services = {
          chrony = {
            enable = lib.mkDefault true;
            enableNTS = lib.mkDefault true;
            servers = lib.mkDefault cfg.timeSync.chronyNts.servers;
          };

          timesyncd.enable = lib.mkForce false;
        };
      })

      (lib.mkIf cfg.dbusBroker.enable {
        services.dbus.implementation = lib.mkDefault "broker";
      })

      (lib.mkIf cfg.unusedServices.enable (
        lib.mkMerge [
          (lib.mkIf cfg.unusedServices.disableAvahi {
            services.avahi.enable = lib.mkOverride 900 false;
          })

          (lib.mkIf cfg.unusedServices.disableGeoclue {
            services.geoclue2.enable = lib.mkOverride 900 false;
          })

          (lib.mkIf cfg.unusedServices.disableModemManager {
            networking.modemmanager.enable = lib.mkOverride 900 false;
          })

          (lib.mkIf cfg.unusedServices.disableAutoUpgrade {
            system.autoUpgrade.enable = lib.mkOverride 900 false;
          })
        ]
      ))
    ]
  );
}
