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
      };

      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
      };
    };
  };
}
