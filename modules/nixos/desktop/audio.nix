{ config, lib, ... }:

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
  /*
    TODO: Add profiles for wireplumber/pipewire settings.
    At minimum:
    - "High quality" = good clock defaults for high fidelity
    - Default, for average quality.
  */
  config = lib.mkIf cfg.enable {
    services.pipewire = {
      enable = true;
      pulse.enable = true;
    };
  };
}
