{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.theorem.nixos.gaming.steam;
in
{
  options.theorem.nixos.gaming.steam.enable = lib.mkEnableOption "Steam gaming profile";

  config = lib.mkIf cfg.enable {
    theorem.nixos.base.nix.unfreePackageNames = [
      "steam"
      "steam-original"
      "steam-run"
      "steam-unwrapped"
    ];

    programs.steam = {
      enable = true;
      # TODO: Don't open the firewall by default.
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      gamescopeSession.enable = false; # TODO: Gamescope should be optional
    };

    # TODO: Gamescope should be optional
    programs.gamescope = {
      enable = true;
      capSysNice = false;
    };

    hardware.steam-hardware.enable = true;
    programs.gamemode.enable = true; # TODO: Move to a general "Gaming" module with Mangohud and others. Have that module enabled whenever any gaming module is enabled.

    environment.systemPackages = with pkgs; [
      steam-run
    ];
  };
}
