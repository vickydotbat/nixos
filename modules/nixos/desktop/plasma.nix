{
  config,
  lib,
  ...
}:
let
  cfg = config.theorem.nixos.desktop.plasma;
in
{
  options.theorem.nixos.desktop.plasma.enable = lib.mkEnableOption "Plasma desktop profile";

  config = lib.mkIf cfg.enable {
    services = {
      displayManager = {
        sddm.enable = lib.mkForce false; # Not supported for 26.05
        plasma-login-manager.enable = true;
      };
      desktopManager = {
        plasma6.enable = true;
      };
    };
    programs = {
      gnupg.agent.enable = true;
      kdeconnect.enable = lib.mkDefault true;
    };
    security = {
      pam.services = {
        sddm.enableKwallet = lib.mkDefault true;
        fprintd.enable = lib.mkDefault false;
        login.fprintAuth = lib.mkDefault false;
      };
    };
  };
}
