{
  config,
  lib,
  pkgs,
  ...
}:
# Small base package set for every maintained host. Keep this list boring:
# repair tools, archive tools, and fallback editors that should exist even when
# a richer profile fails. Feature-bearing applications belong in their own
# modules or host profiles.
let
  cfg = config.theorem.nixos.base.packages;
in
{
  options.theorem.nixos.base.packages.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Install the small base package set expected on every maintained host.
      Disable only for deliberately austere images.
    '';
  };

  config = lib.mkIf cfg.enable {
    # Repair shells may cross user boundaries through sudo/run0. Keep common
    # terminal descriptions available system-wide so root-side tools do not
    # fail when a modern terminal exports its precise TERM name.
    environment.enableAllTerminfo = true;

    environment.systemPackages = with pkgs; [
      git
      nano
      vim
      unzip
      zip
    ];
  };
}
