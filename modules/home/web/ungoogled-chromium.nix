{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.home.web.ungoogled-chromium;
in
{
  # Ungoogled Chromium is a fallback browser for Gecko breakage and web
  # development checks. This module intentionally avoids persistence hooks, so
  # impermanent hosts discard its profile unless a user opts into state elsewhere.
  options.theorem.home.web.ungoogled-chromium.enable = lib.mkEnableOption "Ungoogled Chromium";

  config = lib.mkIf cfg.enable {
    programs.chromium = {
      enable = true;
      package = pkgs.ungoogled-chromium;
    };
  };
}
