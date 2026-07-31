{
  config,
  lib,
  pkgs,
  ...
}:
# Ungoogled Chromium is a fallback browser for Gecko breakage and web
# development checks. This module intentionally avoids persistence hooks, so
# impermanent hosts discard its profile unless a user opts into state elsewhere.
let
  cfg = config.theorem.home.web.ungoogled-chromium;
in
{
  options.theorem.home.web.ungoogled-chromium.enable = lib.mkEnableOption "Ungoogled Chromium";

  config = lib.mkIf cfg.enable {
    programs.chromium = {
      enable = true;
      package = pkgs.ungoogled-chromium;
    };

    # An older generation linked the whole `NativeMessagingHosts` directory into
    # the store. Once that generation is garbage collected the link dangles, and
    # the next activation dies on `mkdir: File exists` because Home Manager only
    # cleans links it can still trace to a generation it knows about. Drop dead
    # links under the profile directory first, so activation stays idempotent.
    home.activation.pruneDanglingChromiumLinks =
      lib.hm.dag.entryBefore [ "checkLinkTargets" ]
        ''
          run ${pkgs.findutils}/bin/find "${config.home.homeDirectory}/.config/chromium" \
            -maxdepth 2 -xtype l -delete 2>/dev/null || true
        '';
  };
}
