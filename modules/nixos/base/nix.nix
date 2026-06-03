{ config, lib, ... }:
# TODO: These are global defaults. Use lib.mkDefault where necessary but this should not be put on a toggle.
let
  cfg = config.theorem.nixos.base.nix;
in
{
  options.theorem.nixos.base.nix.enable = lib.mkEnableOption "base Nix daemon configuration";
  options.theorem.nixos.base.nix.unfreePackageNames = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = ''
      Exact package names allowed through the unfree predicate.
      Modules and hosts should add only packages they actually enable.
    '';
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config = {
      allowUnfree = false;
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) cfg.unfreePackageNames;
    };

    nix = {
      settings = {
        auto-optimise-store = true;
        experimental-features = [
          "nix-command"
          "flakes"
        ];

        # Allow DevEnv to merge binary caches with the system Nix store
        extra-substituters = [
          "https://devenv.cachix.org"
        ];
        extra-trusted-public-keys = [
          "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        ];
      };

    };

    programs.nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep 5 --keep-since 7d";
      };
    };

    # Reduces the suffering of the average user.
    programs.nix-ld.enable = lib.mkDefault true;
  };
}
