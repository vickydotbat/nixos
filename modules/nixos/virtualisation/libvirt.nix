{
  config,
  lib,
  pkgs,
  repository,
  selectedUsers,
  ...
}:
# Libvirt substrate for local VM testing. The `libvirtd` group can control
# virtual machines through the daemon, so membership follows repository
# stewardship rather than every graphical login.
let
  cfg = config.theorem.nixos.virtualisation.libvirt;
  repositoryGroup = repository.group or "nixcfg";

  isRepositoryUser =
    _name: user:
    (user.group or null) == repositoryGroup || lib.elem repositoryGroup (user.extraGroups or [ ]);

  libvirtUsers = lib.attrNames (lib.filterAttrs isRepositoryUser selectedUsers);
in
{
  options.theorem.nixos.virtualisation.libvirt = {
    enable = lib.mkEnableOption "Libvirt and virt-manager VM management stack";

    spiceUSBRedirection.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Install the SPICE USB redirection helper. This is useful for VM testing
        that needs direct USB device handoff, but it is a setuid helper and
        gives local users arbitrary access to USB devices. Enable it only on a
        host that accepts that repair tradeoff.
      '';
    };

    swtpm.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Allow libvirt QEMU guests to use an emulated TPM through swtpm. Keep
        enabled for modern UEFI guests and installer tests that expect TPM
        hardware to exist, even when the target NixOS host does not bind
        secrets to TPM state.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.virt-manager.enable = true;

    virtualisation = {
      libvirtd = {
        enable = true;
        qemu = {
          runAsRoot = false;
          swtpm.enable = cfg.swtpm.enable;
        };
      };

      spiceUSBRedirection.enable = cfg.spiceUSBRedirection.enable;
    };

    environment.systemPackages = with pkgs; [
      virt-viewer
    ];

    users.users = lib.genAttrs libvirtUsers (_: {
      extraGroups = lib.mkAfter [ "libvirtd" ];
    });
  };
}
