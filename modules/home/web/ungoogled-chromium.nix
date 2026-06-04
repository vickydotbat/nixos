/*
  TODO

  NOTE: This is only a compatibility package for situations where gecko/firefox
  does not work. Light hardening to keep its use safe is viable but should not
  break browser usability. It serves primarily as a fallback and web development
  testing tool.

  It is not intended to be impermanent. Storage of the browser should always be
  volatile, which it already should be on an impermanent system. For systems that
  employ different disk strategies, it should be kept in mind that this module
  may need additional configuration to achieve an acceptable volatility state.
*/

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
  options.theorem.home.web.ungoogled-chromium.enable = lib.mkEnableOption "Ungoogled Chromium";

  config = lib.mkIf cfg.enable {
    programs.chromium = {
      enable = true;
      package = pkgs.ungoogled-chromium;
    };
  };
}
