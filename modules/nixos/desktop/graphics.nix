{
  config,
  lib,
  pkgs,
  ...
}:
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
