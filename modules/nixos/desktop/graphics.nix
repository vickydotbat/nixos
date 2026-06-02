{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.nixos.desktop.graphics;
in
{
  options.theorem.nixos.desktop.graphics.enable = lib.mkEnableOption "desktop graphics support";

  config = lib.mkIf cfg.enable {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    environment.systemPackages = with pkgs; [
      vulkan-tools
    ];
  };
}
