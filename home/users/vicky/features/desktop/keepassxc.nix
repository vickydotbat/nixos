{
  programs.keepassxc = {
    enable = true;
    autostart = true;

    settings = {
      # Use system tray
      GUI.ShowTrayIcon = true;
      GUI.MinimizeOnClose = true;
      GUI.MinimizeToTray = true;

      GUI.ColorPasswords = true;
      GUI.CompactMode = true;

      # DropToBackgroundOnCopy = true;

      PasswordGenerator.Length = 32;
    };
  };
}
