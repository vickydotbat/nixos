{
  config,
  lib,
  ...
}:
let
  cfg = config.theorem.nixos.desktop.plasma;
in
{
  options.theorem.nixos.desktop.plasma = {
    enable = lib.mkEnableOption "Plasma desktop profile";

    fwupdRefreshTimer.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable fwupd's unattended metadata refresh timer. Plasma enables fwupd
        by default, but the timer runs outside an active desktop session and
        can fail Polkit authorization during rebuild activation. Keep it off by
        default; use Discover or `fwupdmgr refresh` deliberately when firmware
        metadata is part of a maintenance rite.
      '';
    };
  };

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

    systemd = lib.mkIf (!cfg.fwupdRefreshTimer.enable) {
      services.fwupd-refresh.enable = lib.mkForce false;
      timers.fwupd-refresh.enable = lib.mkForce false;
    };

    system.activationScripts.clearFwupdRefreshFailure = lib.mkIf (!cfg.fwupdRefreshTimer.enable) {
      supportsDryActivation = false;
      text = ''
        if [ -d /run/systemd/system ]; then
          ${config.systemd.package}/bin/systemctl reset-failed fwupd-refresh.service fwupd-refresh.timer 2>/dev/null || true
        fi
      '';
    };
  };
}
