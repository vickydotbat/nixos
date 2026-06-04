{
  inputs,
  pkgs,
}:

let
  lib = inputs.nixpkgs.lib;
  solanine = inputs.self.nixosConfigurations.solanine;
  tmpfsConfig = solanine.config;
  btrfsConfig =
    (solanine.extendModules {
      modules = [
        {
          theorem.nixos.base.persistence.root.mode = lib.mkForce "btrfs";
        }
      ];
    }).config;

  rollbackService = btrfsConfig.boot.initrd.systemd.services.rollback-root;
in
assert !(tmpfsConfig.boot.initrd.systemd.services ? rollback-root);
assert btrfsConfig.boot.initrd.systemd.enable;
assert btrfsConfig.fileSystems."/".fsType == "btrfs";
assert lib.elem "subvol=@root" btrfsConfig.fileSystems."/".options;
assert rollbackService.description == "Roll back Btrfs root to blank snapshot";
assert rollbackService.before == [ "sysroot.mount" ];
assert rollbackService.requiredBy == [ "sysroot.mount" ];
assert rollbackService.unitConfig.DefaultDependencies == "no";
assert rollbackService.serviceConfig.Type == "oneshot";
assert lib.hasInfix "Missing Btrfs blank root snapshot" rollbackService.script;
assert lib.hasInfix "btrfs subvolume snapshot" rollbackService.script;
pkgs.runCommand "btrfs-rollback-boundary" { } ''
  touch "$out"
''
