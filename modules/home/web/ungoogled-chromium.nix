{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:

let
  cfg = config.theorem.home.web.ungoogled-chromium;
in
{
  options.theorem.home.web.ungoogled-chromium.enable = lib.mkEnableOption "Ungoogled Chromium";

  config = lib.mkIf cfg.enable (
    import ../../../home/raw/vicky/features/web/ungoogled-chromium.nix args
  );
}
