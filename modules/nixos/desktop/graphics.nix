{
  config,
  lib,
  pkgs,
  ...
}:
# Graphics support follows declared graphical roles. Vulkan diagnostics and
# 32-bit libraries are useful on desktops and Steam hosts, but headless systems
# should not inherit them by accident.
let
  cfg = config.theorem.nixos.desktop.graphics;
  desktopNeedsGraphics =
    config.theorem.nixos.desktop.plasma.enable
    || config.theorem.nixos.gaming.steam.enable
    || config.theorem.nixos.desktop.jailwolf.enable;
in
{
  options.theorem.nixos.desktop.graphics.enable = lib.mkOption {
    type = lib.types.bool;
    default = desktopNeedsGraphics;
    defaultText = lib.literalExpression ''
      theorem.nixos.desktop.plasma.enable
      || theorem.nixos.gaming.steam.enable
      || theorem.nixos.desktop.jailwolf.enable
    '';
    description = "Enable desktop graphics support when a graphical system theorem needs it.";
  };

  config = lib.mkIf cfg.enable {
    hardware.graphics = {
      enable = true;
      enable32Bit = lib.mkDefault true;
    };

    environment.systemPackages = with pkgs; [
      vulkan-tools
    ];
  };
}
