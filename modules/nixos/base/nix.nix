{ config, lib, ... }:

let
  cfg = config.vicky.nixos.base.nix;
in
{
  options.vicky.nixos.base.nix.enable = lib.mkEnableOption "base Nix daemon configuration";

  config = lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfree = true;

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

      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };
    };

    programs.nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep 5 --keep-since 7d";
      };
    };
  };
}
