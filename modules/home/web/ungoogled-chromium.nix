{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

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
  };
}
