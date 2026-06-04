{
  config,
  lib,
  osConfig ? null,
  ...
}:

# XDG user-directory and desktop integration baseline. It follows the system
# graphics profile when Home Manager is evaluated inside NixOS, but remains off
# by default for standalone Home flakes where no system graphics theorem exists.
let
  cfg = config.theorem.home.base.xdg;
  graphicsEnabled =
    if osConfig == null then false else osConfig.theorem.nixos.desktop.graphics.enable or false;
in
{
  options.theorem.home.base.xdg.enable = lib.mkOption {
    type = lib.types.bool;
    default = graphicsEnabled;
    defaultText = lib.literalExpression ''
      osConfig.theorem.nixos.desktop.graphics.enable
    '';
    description = ''
      Enable XDG user directories, MIME defaults, and autostart support for
      graphics-enabled systems.
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
