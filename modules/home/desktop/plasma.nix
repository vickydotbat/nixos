{
  config,
  lib,
  options,
  ...
}:
# Neutral Plasma Manager substrate. Personal layout, shortcuts, MIME defaults,
# KDE Connect, and wallet persistence belong in the selecting user profile.
let
  cfg = config.theorem.home.desktop.plasma;
  hasPlasmaManager = options.programs ? plasma;
in
{
  options.theorem.home.desktop.plasma.enable = lib.mkEnableOption "Plasma Manager user substrate";

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = !cfg.enable || hasPlasmaManager;
          message = ''
            theorem.home.desktop.plasma.enable requires the Plasma Manager Home
            module. Import inputs.plasma-manager.homeModules.plasma-manager
            before selecting the Plasma Home substrate.
          '';
        }
      ];
    }
    (lib.optionalAttrs hasPlasmaManager {
      programs.plasma.enable = lib.mkIf cfg.enable true;
    })
  ];
}
