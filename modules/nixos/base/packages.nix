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

  # Terminals a Home Manager user enables through `theorem.home.shell.*`.
  # Add a terminal here when it gains a module of its own.
  terminals = {
    kitty = homeConfig: homeConfig.programs.kitty.package;
    ghostty = homeConfig: homeConfig.programs.ghostty.package;
  };

  enabledTerminfo = lib.concatMap (
    homeConfig:
    lib.concatLists (
      lib.mapAttrsToList (
        name: package:
        lib.optional (homeConfig.theorem.home.shell.${name}.enable or false) (package homeConfig).terminfo
      ) terminals
    )
  ) (lib.attrValues (config.home-manager.users or { }));
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
    # Repair shells may cross user boundaries through sudo/run0, and the root
    # side does not inherit a user's TERMINFO_DIRS. Install system-wide only
    # the terminfo of terminals a user actually enables. ncurses covers the
    # rest. `environment.enableAllTerminfo` builds every terminal it lists, so
    # one broken emulator upstream blocks every rebuild.
    environment.systemPackages =
      (with pkgs; [
        git
        nano
        vim
        unzip
        zip
        python3
      ])
      ++ enabledTerminfo;
  };
}
