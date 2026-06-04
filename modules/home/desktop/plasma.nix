{
  config,
  lib,
  ...
}:
# Neutral Plasma Manager substrate. Personal layout, shortcuts, MIME defaults,
# KDE Connect, and wallet persistence belong in the selecting user profile.
let
  cfg = config.theorem.home.desktop.plasma;
in
{
  options.theorem.home.desktop.plasma.enable = lib.mkEnableOption "Plasma Manager user substrate";

  config = lib.mkIf cfg.enable {
    programs.plasma.enable = true;
  };
}
