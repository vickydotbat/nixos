{ config, lib, ... }:

# PipeWire is enabled only when a selected desktop or gaming profile needs sound.
# Audio is useful substrate, but it should still follow an actual host role.
let
  cfg = config.theorem.nixos.desktop.audio;
  desktopNeedsAudio =
    config.theorem.nixos.desktop.plasma.enable || config.theorem.nixos.gaming.steam.enable;
in
{
  options.theorem.nixos.desktop.audio.enable = lib.mkOption {
    type = lib.types.bool;
    default = desktopNeedsAudio;
    defaultText = lib.literalExpression ''
      theorem.nixos.desktop.plasma.enable || theorem.nixos.gaming.steam.enable
    '';
    description = "Enable the desktop audio stack when desktop or gaming theorems need sound.";
  };

  config = lib.mkIf cfg.enable {
    services.pipewire = {
      enable = true;
      pulse.enable = true;
    };
  };
}
