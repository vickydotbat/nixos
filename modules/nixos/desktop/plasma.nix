{
  config,
  lib,
  ...
}:
# TODO: Consider good plasma defaults. Also add other desktop options like GNOME. Allow a switch to enable/disable X11 versions. etc.
let
  cfg = config.theorem.nixos.desktop.plasma;
in
{
  options.theorem.nixos.desktop.plasma.enable = lib.mkEnableOption "Plasma desktop profile";

  config = lib.mkIf cfg.enable {
    services.displayManager.sddm.enable = true;
    services.desktopManager.plasma6.enable = true;
    programs.gnupg.agent.enable = true;
    security.pam.services.sddm = {
      enableKwallet = true;
    };
    programs.kdeconnect.enable = true;
  };
}
