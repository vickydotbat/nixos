{ config, lib, ... }:

let
  cfg = config.theorem.nixos.desktop.audio;
in
{
  options.theorem.nixos.desktop.audio.enable = lib.mkEnableOption "desktop audio stack";

  config = lib.mkIf cfg.enable {
    services.pipewire = {
      enable = true;
      pulse.enable = true;
    };
  };
}
