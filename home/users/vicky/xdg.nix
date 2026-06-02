{
  xdg = {
    enable = true;

    # Generates user-dirs.dirs.
    userDirs = {
      enable = true;
      createDirectories = false;
      setSessionVariables = true;

      desktop = "$HOME/Desktop";
      documents = "$HOME/Documents";
      download = "$HOME/Downloads";
      music = "$HOME/Music";
      pictures = "$HOME/Pictures";
      publicShare = "$HOME/Public";
      templates = "$HOME/Templates";
      videos = "$HOME/Videos";
      projects = "$HOME/Projects";

      extraConfig = {
        REPOSITORIES = "$HOME/Repositories";
        GAMES = "$HOME/Games";
        BACKUPS = "$HOME/Backups";
        APPS = "$HOME/Applications";
      };
    };

    mimeApps = {
      enable = true;
    };

    autostart = {
      enable = true;
    };
  };
}
