{ config, lib, ... }:

let
  cfg = config.vicky.nixos.desktop.audio;
in
{
  options.vicky.nixos.desktop.audio.enable = lib.mkEnableOption "desktop audio stack";

  config = lib.mkIf cfg.enable {
    services.pipewire = {
      enable = true;
      pulse.enable = true;
    };
  };
}
