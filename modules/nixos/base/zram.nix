{
  config,
  lib,
  ...
}:
# TODO: Add notes here
let
  cfg = config.theorem.nixos.base.zram;
in
{
  options.theorem.nixos.base.zram = {
    enable = lib.mkEnableOption "base ZRAM configuration";
  };

  config = lib.mkIf cfg.enable {
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 50;
      priority = 100;
    };

    # TODO: Make swapfile default to priority 10

    boot.kernel.sysctl = {
      "vm.swappiness" = 100;
      "vm.page-cluster" = 0;
    };
  };
}
