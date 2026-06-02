{
  config,
  inputs,
  lib,
  osConfig ? null,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.base.xdg;
  graphicsEnabled = (osConfig.theorem.nixos.desktop.graphics.enable or false);
  desktopAppEnabled =
    let
      home = config.theorem.home;
    in
    lib.any (enabled: enabled) [
      (home.desktop.blender.enable or false)
      (home.desktop.discord.enable or false)
      (home.desktop.gimp.enable or false)
      (home.desktop.keepassxc.enable or false)
      (home.desktop.obsidian.enable or false)
      (home.desktop.plasma.enable or false)
      (home.desktop.spicetify.enable or false)
      (home.editor.vscode.enable or false)
      (home.web.firefox.enable or false)
      (home.web.ungoogled-chromium.enable or false)
    ];
in
{
  options.theorem.home.base.xdg.enable = lib.mkOption {
    type = lib.types.bool;
    default = graphicsEnabled && desktopAppEnabled;
    defaultText = lib.literalExpression ''
      osConfig.theorem.nixos.desktop.graphics.enable && any desktop/app theorem is enabled
    '';
    description = ''
      Enable XDG user directories, MIME defaults, and autostart support for
      graphics-enabled systems with desktop applications.
    '';
  };

  config = lib.mkIf cfg.enable {
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
  };
}
