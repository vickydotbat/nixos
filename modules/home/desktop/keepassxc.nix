{
  config,
  lib,
  ...
}:
# KeePassXC carries password-manager posture for the user's desktop session.
# Autostart, tray behavior, and native-messaging repair live here because an
# impermanent host should not need mutable GUI clicks to recover the vault.
let
  cfg = config.theorem.home.desktop.keepassxc;
in
{
  options.theorem.home.desktop.keepassxc = {
    enable = lib.mkEnableOption "KeePassXC";

    autostart.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Start KeePassXC automatically on login. Password database availability
        is a daily workflow choice, but this default keeps an impermanent
        desktop from forgetting that the vault should be ready after login.
      '';
    };

    tray.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Keep KeePassXC available from the desktop tray.";
    };

    minimizeToTray = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Minimize KeePassXC to the tray instead of treating a window close as
        exit. This keeps the vault resident without demanding a visible window.
      '';
    };

    compactMode = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use KeePassXC's compact interface mode.";
    };

    passwordGenerator.length = lib.mkOption {
      type = lib.types.ints.positive;
      default = 32;
      description = "Default generated password length.";
    };

    browser.updateNativeMessagingManifest.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Let KeePassXC update browser native-messaging manifests at startup.
        Home Manager installs those manifests declaratively, so the repairable
        default is to leave KeePassXC's mutable updater disabled.
      '';
    };

    extraSettings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = ''
        Additional KeePassXC INI settings merged over the reusable defaults.
        Use this for user workflow details that do not belong in the shared
        desktop mechanism.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.keepassxc = {
      enable = true;
      autostart = cfg.autostart.enable;

      settings = lib.recursiveUpdate {
        Browser.UpdateBinaryPath = cfg.browser.updateNativeMessagingManifest.enable;

        # Use system tray
        GUI.ShowTrayIcon = cfg.tray.enable;
        GUI.MinimizeOnClose = cfg.minimizeToTray;
        GUI.MinimizeToTray = cfg.minimizeToTray;

        GUI.ColorPasswords = true;
        GUI.CompactMode = cfg.compactMode;

        PasswordGenerator.Length = cfg.passwordGenerator.length;
      } cfg.extraSettings;
    };
  };
}
